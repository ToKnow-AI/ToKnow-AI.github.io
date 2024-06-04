from typing import Callable
from pyppeteer.page import Page
from PIL import Image
import io
import inspect
from .get_browser import get_browser_page_async

async def web_screenshot_async(
        url: str, 
        *, 
        action: Callable[[Page], None] = None, 
        executable_path: str = None,
        width: int = 0,
        height: int = 0) -> Image.Image:
    
    page, browser = await get_browser_page_async(executable_path, width = width, height = height)
    
    # Go to the specified URL
    await page.goto(url)
    if action:
        if inspect.iscoroutinefunction(action):
            await action(page)
        else:
            action(page)
    # Take a screenshot and get the image bytes
    screenshot_bytes = await page.screenshot({'fullPage': True })
    # Close the browser
    await browser.close()
    # Convert the bytes to a PIL Image
    image = Image.open(io.BytesIO(screenshot_bytes))
    return image