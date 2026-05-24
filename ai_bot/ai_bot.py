import asyncio
import logging
import os
import subprocess
from pathlib import Path

from telegram import Update
from telegram.ext import ApplicationBuilder, MessageHandler, filters, ContextTypes
import ollama

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

TOKEN = os.environ.get("TELEGRAM_TOKEN", "YOUR_TELEGRAM_TOKEN_HERE")
SKILL_SEARCH_SCRIPT = Path.home() / "nanobot/skills/yt-recommender/scripts/search_yt.py"


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_text = update.message.text
    logging.info("Incoming task request parsed: %s", user_text)

    system_prompt = (
        "You are a helpful AI assistant running locally on a minimal-footprint home machine "
        "using Xubuntu Minimal. You are efficient, concise, and aware of "
        "your hardware limitations. Your creator is Sathia."
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_text},
    ]

    # Invoke yt-recommender skill when the user asks for video suggestions.
    if SKILL_SEARCH_SCRIPT.exists() and any(
        kw in user_text.lower() for kw in ("youtube", "video", "watch", "recommend")
    ):
        try:
            result = subprocess.check_output(
                ["python3", str(SKILL_SEARCH_SCRIPT), user_text],
                stderr=subprocess.DEVNULL,
                text=True,
            )
            messages.insert(
                1,
                {
                    "role": "system",
                    "content": (
                        "The yt-recommender skill returned these candidate videos. "
                        "Select the best educational options and reply with titles and URLs:\n"
                        f"{result}"
                    ),
                },
            )
        except subprocess.CalledProcessError as exc:
            logging.warning("yt-recommender skill failed: %s", exc)

    try:
        response = ollama.chat(
            model="llama3.2:3b",
            messages=messages,
        )
        await update.message.reply_text(response["message"]["content"])
    except Exception as exc:
        logging.error("Inference processing failure occurred: %s", exc)
        await update.message.reply_text(
            "Engine error occurred during internal computing pass."
        )


if __name__ == "__main__":
    app = ApplicationBuilder().token(TOKEN).build()
    app.add_handler(MessageHandler(filters.TEXT & (~filters.COMMAND), handle_message))
    print("Script connected and listening via polling interface loops...")
    app.run_polling()
