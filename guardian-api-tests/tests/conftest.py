# Load .env from project root so GUARDIAN_API_BASE_URL is set for tests
from pathlib import Path

try:
    import dotenv

    _project_root = Path(__file__).resolve().parent.parent
    dotenv.load_dotenv(_project_root / ".env")
except ImportError:
    pass  # python-dotenv not installed; use env vars or --base-url
