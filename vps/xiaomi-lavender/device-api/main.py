from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from pathlib import Path

app = FastAPI(title="Device Control API")

BATTERY_CAPACITY = Path("/sys/class/power_supply/qcom-battery/capacity")
BRIGHTNESS_PATH = Path("/sys/class/backlight/backlight/brightness")


def read_int(path: Path) -> int:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError) as e:
        raise HTTPException(status_code=500, detail=f"Cannot read {path}: {e}")


class BrightnessRequest(BaseModel):
    brightness: int = Field(ge=0, le=2000)


@app.get("/battery")
def get_battery():
    """Return battery capacity as a percentage."""
    return {"capacity": read_int(BATTERY_CAPACITY), "unit": "%"}


@app.get("/brightness")
def get_brightness():
    """Return current brightness value."""
    return {"brightness": read_int(BRIGHTNESS_PATH)}


@app.post("/brightness")
def set_brightness(request: BrightnessRequest):
    """Set screen brightness."""
    try:
        BRIGHTNESS_PATH.write_text(str(request.brightness))
    except OSError as e:
        raise HTTPException(
            status_code=500,
            detail=f"Cannot set brightness: {e}. Check permissions."
        )

    return {"brightness": request.brightness, "status": "ok"}

