from collections.abc import Iterator
from dataclasses import dataclass

import av
import numpy as np

POINTS = 440
WIDTH = 220


@dataclass(frozen=True)
class Frame:
    index: int
    time: float
    gray: np.ndarray
    rgb: np.ndarray | None


def size(path: str, width: int = WIDTH) -> tuple[int, int]:
    with av.open(path) as container:
        stream = container.streams.video[0]
        w, h = stream.codec_context.width, stream.codec_context.height
    if w > h:
        raise ValueError(f"{path} is landscape ({w}x{h}); expected a portrait iPhone recording")
    return width, round(h * width / w / 2) * 2


def frames(path: str, width: int = WIDTH, rgb: bool = False) -> Iterator[Frame]:
    """Every frame in presentation order, downscaled, with its real timestamp from the first frame."""
    w, h = size(path, width)
    with av.open(path) as container:
        stream = container.streams.video[0]
        stream.thread_type = "AUTO"
        start = None
        for index, frame in enumerate(container.decode(stream)):
            start = frame.time if start is None else start
            small = frame.reformat(w, h, format="rgb24", interpolation="AREA").to_ndarray()
            gray = (small @ np.array([0.299, 0.587, 0.114], np.float32)).astype(np.float32)
            yield Frame(index, frame.time - start, gray, small if rgb else None)
