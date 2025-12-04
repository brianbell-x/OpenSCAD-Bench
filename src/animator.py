"""
Animator module for generating rotating WebM animations from STL files using vedo.
"""

import logging
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import numpy as np
import vedo

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class AnimationResult:
    """Result of an animation generation attempt."""
    success: bool
    output_path: Optional[Path]
    error: Optional[str]
    animation_time: float


def animate_stl(
    stl_path: Path,
    output_path: Optional[Path] = None,
    duration: float = 6.0,
    fps: int = 24,
    resolution: tuple[int, int] = (800, 600),
    ffmpeg_path: Optional[str] = None,
) -> AnimationResult:
    """
    Generates a rotating WebM animation from an STL file.

    Args:
        stl_path: Path to the input STL file.
        output_path: Path for output WebM file (default: same as stl_path but with .webm extension).
        duration: Duration in seconds for full 360° rotation (default: 3.0).
        fps: Frames per second (default: 24).
        resolution: Tuple of (width, height) for output video (default: (800, 600)).
        ffmpeg_path: Optional path to ffmpeg executable.

    Returns:
        AnimationResult dataclass with success status, output path, error message, and animation time.
    """
    start_time = time.perf_counter()

    # Ensure stl_path is a Path object
    stl_path = Path(stl_path)

    if output_path is None:
        output_path = stl_path.with_suffix(".webm")
    else:
        output_path = Path(output_path)

    logger.info(f"Starting animation generation for {stl_path}")

    try:
        if not stl_path.exists():
            raise FileNotFoundError(f"STL file not found: {stl_path}")

        # Configure ffmpeg path if provided
        if ffmpeg_path:
            # Add ffmpeg directory to PATH so vedo/imageio can find it
            ffmpeg_dir = str(Path(ffmpeg_path).parent)
            os.environ["PATH"] = ffmpeg_dir + os.pathsep + os.environ["PATH"]

        # Initialize vedo plotter
        plt = vedo.Plotter(offscreen=True, size=resolution, bg="#1e1e1e")

        # Load mesh
        mesh = vedo.load(str(stl_path))
        if mesh is None:
            raise ValueError(f"Failed to load mesh from {stl_path}")

        mesh.c("#168FFF")
        plt += mesh
        plt.show(interactive=False)

        # Create video
        # Ensure output directory exists
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Use imageio backend which is more reliable on Windows than ffmpeg backend
        # (vedo's ffmpeg backend uses os.system with single quotes which fails on Windows)
        # We must manually write the video using imageio to specify the codec for WebM output
        # because vedo.Video doesn't pass extra arguments to imageio.get_writer
        import imageio
        
        vid = vedo.Video(
            str(output_path),
            duration=duration,
            fps=fps,
            backend="imageio"
        )

        # Generate tilted ring camera orbit (electron style)
        # Azimuth: Linear 0->360
        # Elevation: Sinusoidal +/- 45 degrees, 1 full cycle
        # Note: Since we want it to move "half as slow" but duration is doubled (6s),
        # we still want exactly one full rotation (360 deg) over the full duration.
        n_frames = int(fps * duration)
        azimuths = np.linspace(0, 360, n_frames, endpoint=False)
        elevations = 45 * np.sin(np.linspace(0, 2 * np.pi, n_frames, endpoint=False))

        current_azimuth = 0.0
        current_elevation = 0.0

        for i in range(n_frames):
            # Calculate deltas relative to current position
            d_az = azimuths[i] - current_azimuth
            d_el = elevations[i] - current_elevation

            plt.camera.Azimuth(d_az)
            plt.camera.Elevation(d_el)
            plt.render()
            vid.add_frame()

            current_azimuth = azimuths[i]
            current_elevation = elevations[i]
        
        # Manually write frames to video file with correct codec
        writer = imageio.get_writer(str(output_path), fps=fps, codec="libvpx-vp9")
        for f in vid.frames:
            writer.append_data(imageio.imread(f))
        writer.close()
        
        # Cleanup temporary directory created by vedo
        vid.tmp_dir.cleanup()
        
        # We don't call vid.close() because we already wrote the video and cleaned up
        
        plt.close()

        elapsed_time = time.perf_counter() - start_time
        
        # Verify the output file was actually created and has content
        # vedo doesn't raise exceptions when ffmpeg fails, so we must check manually
        if not output_path.exists():
            raise RuntimeError(f"Animation file was not created: {output_path}")
        
        file_size = output_path.stat().st_size
        if file_size < 1000:  # A valid webm should be at least 1KB
            raise RuntimeError(
                f"Animation file appears to be empty or corrupted ({file_size} bytes). "
                "This usually means ffmpeg failed - check that ffmpeg is installed and in PATH."
            )
        
        logger.info(f"Animation generated successfully at {output_path} in {elapsed_time:.2f}s")

        return AnimationResult(
            success=True,
            output_path=output_path,
            error=None,
            animation_time=elapsed_time,
        )

    except Exception as e:
        elapsed_time = time.perf_counter() - start_time
        error_msg = str(e)
        logger.error(f"Failed to generate animation for {stl_path}: {error_msg}")

        return AnimationResult(
            success=False,
            output_path=None,
            error=error_msg,
            animation_time=elapsed_time,
        )