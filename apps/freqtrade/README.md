# Freqtrade

A free and open source crypto trading bot written in Python. Freqtrade allows you to develop and test trading strategies with backtesting, optimize strategies with machine learning, and trade on multiple cryptocurrency exchanges with automation.

**Disclaimer**: This software is for educational purposes only. Do not risk money which you are afraid to lose. USE THE SOFTWARE AT YOUR OWN RISK.

## Services

| Service | Role | Port | Network |
|---------|------|------|---------|
| `freqtrade` | Trading bot with REST API and FreqUI web interface | 8080 | `home_network` (public via Traefik) + `home_freqtrade_network` (private, reserved for future use) |

## Access

- **FreqUI Web Interface**: `https://freqtrade.${DOMAIN}` or `http://freqtrade.localhost` (if using localhost)
- **REST API**: `http://freqtrade.${DOMAIN}/api/v1` with authentication
- **Login Credentials**: Use `FREQTRADE_API_USERNAME` and `FREQTRADE_API_PASSWORD` from `.env`

## Starting this App

### From the app folder:

```bash
cd apps/freqtrade
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:

```bash
make up-freqtrade
```

## Automatic Initialization (Entrypoint Override)

This Freqtrade deployment uses a **custom Python entrypoint script** that automatically initializes the bot on first start.

**Quick Overview:**
- Automatically creates config.json on first launch
- Sets default exchange to Kraken (avoids geo-blocking)
- Optionally downloads official strategies
- Subsequent starts skip initialization

**For detailed technical documentation**, see [ENTRYPOINT.md](ENTRYPOINT.md) which explains:
- How Docker entrypoint override works
- How arguments are passed and processed
- Example logs from first and subsequent starts
- Using different freqtrade commands with the entrypoint

**Key Concept**: The entrypoint is flexible and works with any freqtrade subcommand (backtesting, download-data, show-config, etc.).

## Custom Scripts and Automation

This Freqtrade deployment includes two custom automation scripts:

1. **entrypoint.py** - Handles automatic initialization on first start
2. **strategy_downloader.py** - Optionally downloads official freqtrade strategies from GitHub

**For complete documentation on both scripts**, including:
- How to customize each script
- How to toggle strategy downloads
- Initialization flow diagram
- Example logs from startup
- Customization guide

See [SCRIPTS.md](SCRIPTS.md)

## Configuration

### Initial Setup

1. **Start the bot**: Use one of the commands above
2. **Default Configuration**: On first start, the entrypoint script automatically creates config.json with:
   - **Exchange**: `kraken` (not Binance—avoids HTTP 451 "Service unavailable from restricted location" errors)
   - **Dry Run**: Enabled (safe for testing)
   - **Stake Currency**: USDT
   - **Strategy**: Will be set to `SampleStrategy` at runtime via command-line flag
3. **Access FreqUI**: Navigate to `https://freqtrade.${DOMAIN}` (or `http://freqtrade.localhost`)
4. **Log in**: Use credentials from `.env` file
5. **Customize Configuration**:
   - If you want to use a different exchange, edit `config.json` in the volume
   - Configure trading pairs and strategy
   - Set stake currency and amount
   - Adjust risk management (stoploss, take-profit, etc.)

### Initial Configuration Files

The bot will automatically create the following structure in the `user_data/` volume:

```
user_data/
├── config.json          # Main bot configuration (edit via FreqUI)
├── strategies/          # Your trading strategy files
├── backtest_results/    # Backtesting output
├── data/                # Downloaded historical OHLCV data
└── logs/                # Bot logs
```

### Important Environment Variables

These variables override `config.json` values and must be set in `.env`:

| Variable | Purpose | Source | Required |
|----------|---------|--------|----------|
| `FREQTRADE_API_USERNAME` | FreqUI login username | Local `.env` | Yes |
| `FREQTRADE_API_PASSWORD` | FreqUI login password | Local `.env` | Yes |
| `FREQTRADE_JWT_SECRET` | JWT token secret for API authentication | Local `.env` | Yes |
| `FREQTRADE_WS_TOKEN` | WebSocket token for real-time updates | Local `.env` | Yes |
| `FREQTRADE_TELEGRAM_ENABLED` | Enable/disable Telegram notifications | Local `.env` | No (defaults to false) |
| `FREQTRADE_TELEGRAM_TOKEN` | Telegram bot token from BotFather | Local `.env` | Only if Telegram enabled |
| `FREQTRADE_TELEGRAM_CHAT_ID` | Your Telegram chat ID for notifications | Local `.env` | Only if Telegram enabled |
| `DOMAIN` | Domain for Traefik routing | Global (root `.env`) | Yes |

**Note**: Freqtrade uses SQLite by default (`sqlite:////freqtrade/user_data/tradesv3.sqlite`). No separate database service is required.

### Configuring Trading Parameters

Once the bot is running, you can configure:

- **Exchange**: Connection details (API keys added later)
- **Trading Pairs**: Whitelist/blacklist currencies
- **Strategy**: Python strategy file selection
- **Stake Currency & Amount**: BTC, ETH, USDT, etc.
- **Timeframe**: 5m, 15m, 1h, 4h, 1d, etc.
- **Dry Run Mode**: Test without real money (recommended first)

**Note**: Exchange API keys and sensitive trading configuration should be added separately to a private `config-private.json` and loaded via the Freqtrade multi-config feature.

### Telegram Notifications (Optional)

Freqtrade can send real-time trade notifications via Telegram. This allows you to monitor trades, check balances, and manage positions directly from your phone.

**To enable Telegram notifications**, see [TELEGRAM.md](TELEGRAM.md) for:
- Step-by-step setup (create bot, get chat ID, configure .env)
- Available Telegram commands for controlling the bot
- Troubleshooting common issues
- Security best practices

## Volumes & Networks

| Volume | Purpose | Type |
|--------|---------|------|
| `home_freqtrade_data` | User data directory (strategies, config, logs, data, SQLite database) | Named |

| Network | Purpose |
|---------|---------||
| `home_network` | External network for Traefik routing (FreqUI access) |
| `home_freqtrade_network` | Internal network (reserved for future expansion, e.g., Redis, additional services) |

## Troubleshooting

### Cannot connect to FreqUI

- Ensure Traefik is running: `make up-traefik` (or check root Makefile)
- Verify `DOMAIN` is set correctly in root `.env`
- Check bot is healthy: `docker logs freqtrade`
- Verify API server is enabled in logs

### Database Issues

- Freqtrade uses SQLite by default (no separate database service needed)
- Database file location: `user_data/tradesv3.sqlite` (inside the volume)
- To inspect the database, use: `docker exec -it freqtrade sqlite3 /freqtrade/user_data/tradesv3.sqlite`
- If database is corrupted, stop the bot and remove/rename the `.sqlite` file to start fresh

### Trading Not Starting

- Verify dry-run mode is enabled for first test
- Check strategy file exists in `user_data/strategies/`
- Review bot logs for syntax/configuration errors
- Ensure at least one trading pair is whitelisted
- Verify stake currency is correctly configured

## Official Documentation

- **Main Documentation**: https://www.freqtrade.io/en/stable/
- **Docker Quickstart**: https://www.freqtrade.io/en/stable/docker_quickstart/
- **Configuration Guide**: https://www.freqtrade.io/en/stable/configuration/
- **Strategy Development**: https://www.freqtrade.io/en/stable/strategy-customization/
- **REST API**: https://www.freqtrade.io/en/stable/rest-api/
- **Telegram Integration**: https://www.freqtrade.io/en/stable/telegram-usage/
- **Backtesting**: https://www.freqtrade.io/en/stable/backtesting/
- **GitHub Repository**: https://github.com/freqtrade/freqtrade
