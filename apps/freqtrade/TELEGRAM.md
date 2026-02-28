# Telegram Notifications

This Freqtrade deployment can send real-time trade notifications via Telegram. This guide shows how to set it up.

## Prerequisites

- A Telegram account
- Basic understanding of Freqtrade configuration

## Setup Steps

### 1. Create a Telegram Bot

Message [@BotFather](https://t.me/botfather) on Telegram and follow these steps:

1. Send `/newbot` command
2. Choose a name for your bot (e.g., "My Freqtrade Bot")
3. BotFather will provide a token, which looks like: `123456789:ABCdefGHIjklmnoPQRstuvWXYZ`
4. Save this token—you'll need it in the next step

For detailed instructions, see [Telegram's Bot Father guide](https://core.telegram.org/bots).

### 2. Get Your Telegram Chat ID

The easiest way to get your chat ID is to use the [@userinfobot](https://t.me/userinfobot) bot:

1. Open Telegram and go to [@userinfobot](https://t.me/userinfobot)
2. Send any message (e.g., `/start`)
3. The bot will reply with your user information, including your **User ID**
4. Save this ID—you'll use it as your `FREQTRADE_TELEGRAM_CHAT_ID`

**Example response from @userinfobot:**
```
👤 User Information
├ User ID: 987654321
├ Username: your_username
├ First name: Your
├ Last name: Name
└ Is bot: No
```

### 3. Update Your .env File

Edit the local `.env` file in `apps/freqtrade/.env` and add/update these variables:

```dotenv
FREQTRADE_TELEGRAM_ENABLED=true
FREQTRADE_TELEGRAM_TOKEN=your_bot_token_here
FREQTRADE_TELEGRAM_CHAT_ID=your_chat_id_here
```

**Example:**
```dotenv
FREQTRADE_TELEGRAM_ENABLED=true
FREQTRADE_TELEGRAM_TOKEN=123456789:ABCdefGHIjklmnoPQRstuvWXYZ
FREQTRADE_TELEGRAM_CHAT_ID=987654321
```

### 4. Restart the Bot

```bash
# From the root folder
make down-freqtrade && make up-freqtrade
```

Once restarted, your bot will start sending Telegram notifications.

## Available Telegram Commands

Once your bot is running, you can interact with it via Telegram. Here are the available commands:

| Command | Description |
|---------|-------------|
| `/start` | Start the bot and show welcome message |
| `/stop` | Stop trading (pause the bot) |
| `/status` | Show current open trades and their status |
| `/profit` | Display total profit/loss and win rate |
| `/balance` | Show account balance and available funds |
| `/forceexit <trade_id>` | Exit a specific trade by ID |
| `/forcesell <trade_id>` | Alias for forceexit (deprecated but still works) |
| `/telegram` | Show Telegram-specific help |
| `/help` | Show all available commands |

**Example Telegram conversation:**
```
You: /status
Bot: ▸ BTC/USDT
   ├ Entry price: 42,500 USDT
   ├ Current price: 43,200 USDT
   └ Profit: +1.64%

You: /profit
Bot: Total Profit: +5.25%
   Trades: 12 | Wins: 9 | Losses: 3
```

## Troubleshooting

### Telegram Bot Not Responding

1. **Verify the bot token and chat ID** are correct in `.env`
2. **Check the container logs**:
   ```bash
   docker logs -f freqtrade | grep -i telegram
   ```
3. **Ensure the bot is running**:
   ```bash
   docker ps | grep freqtrade
   ```
4. **Restart the bot** if you made changes to `.env`:
   ```bash
   make down-freqtrade && make up-freqtrade
   ```

### No Messages Appearing

1. **Message the bot first** - Send any message to your bot to activate it
2. **Check if Telegram is enabled** - Verify `FREQTRADE_TELEGRAM_ENABLED=true` in `.env`
3. **Verify chat ID** - Use the step above to re-confirm your correct chat ID
4. **Check network connectivity** - Ensure the container can reach Telegram's servers

### Rate Limiting

Telegram may rate-limit notifications if too many are sent rapidly. This is normal and temporary. Freqtrade handles this gracefully by queuing messages.

## Privacy & Security

- **Bot Token**: Keep your bot token secret. Anyone with it can control your bot.
- **Chat ID**: While less sensitive, keep this private too.
- **Configuration**: Store sensitive credentials in `.env`, not in `config.json`.
- **.env File**: Never commit `.env` files to version control.

## Advanced Configuration

For more advanced Telegram settings (e.g., custom message formatting, filtering notifications), edit the Freqtrade config.json file:

```json
{
  "telegram": {
    "enabled": true,
    "token": "your_bot_token",
    "chat_id": "your_chat_id",
    "notification_format": "json",
    "balance_dust_level": 0.0
  }
}
```

See the [official Freqtrade Telegram documentation](https://www.freqtrade.io/en/stable/telegram-usage/) for complete options.

## Official Documentation

For more details, see:
- [Freqtrade Telegram Integration](https://www.freqtrade.io/en/stable/telegram-usage/)
- [Telegram Bot API Reference](https://core.telegram.org/bots)
