# Freqtrade

A free and open source crypto trading bot written in Python. Freqtrade allows you to develop and test trading strategies with backtesting, optimize strategies with machine learning, and trade on multiple cryptocurrency exchanges with automation.

**Disclaimer**: This software is for educational purposes only. Do not risk money which you are afraid to lose. USE THE SOFTWARE AT YOUR OWN RISK.

## Services

| Service | Role | Port | Network |
|---------|------|------|---------|
| `freqtrade` | Trading bot with REST API and FreqUI web interface | 8080 | `home_network` (public via Traefik) + `home_freqtrade_network` (private) |
| `freqtrade-postgres` | Dedicated PostgreSQL database for trade history and configuration | 5432 | `home_freqtrade_network` (private, not exposed) |

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

### How It Works

This Freqtrade deployment uses a custom **Python entrypoint script** that **automatically initializes** the bot on first start. Without this automation, you would need to manually run three commands before starting the bot.

**The Problem:**
- The official `freqtradeorg/freqtrade` Docker image requires `config.json` to exist
- It does NOT auto-initialize on first run
- Manual workaround: `docker exec freqtrade freqtrade create-userdir && freqtrade new-config`

**The Solution:**
- Custom [entrypoint.py](entrypoint.py) script that overrides the image's default entrypoint
- Script automatically runs on container start, **before** the bot launches
- If `config.json` is missing, it:
  1. Creates the user directory structure
  2. Generates a new config.json with defaults
  3. Patches the config to use Kraken (avoids Binance geo-restrictions)
  4. Launches freqtrade with all settings configured

### Entrypoint Override Architecture

**Your docker-compose.yml has two fields:**

```yaml
entrypoint: python3 /entrypoint.py          # Overrides the image's default entrypoint
command: freqtrade trade --config ...       # Args passed to the entrypoint script
```

**Docker combines them into a single invocation:**
```bash
python3 /entrypoint.py freqtrade trade --config user_data/config.json --strategy SampleStrategy
```

**How the script processes this:**

1. **Python script receives:**
   ```python
   sys.argv = ['/entrypoint.py', 'freqtrade', 'trade', '--config', 'user_data/config.json', '--strategy', 'SampleStrategy']
   ```

2. **Script checks if config.json exists:**
   - ✅ If YES: Skips initialization, proceeds to launch freqtrade
   - ❌ If NO: Runs full initialization (create-userdir → new-config → exchange patch)

3. **Script launches freqtrade:**
   ```python
   subprocess.run(['freqtrade', 'trade', '--config', 'user_data/config.json', '--strategy', 'SampleStrategy'])
   ```

4. **Freqtrade runs with initialized config and returns exit code to Docker**

### First Start Initialization Output

```
[entrypoint] config.json not found. Running first-time setup...
[entrypoint] Running: Creating user directory structure...
2026-02-28 02:28:26,182 - freqtrade - INFO - freqtrade docker-2026.2-dev-f7b11c51
2026-02-28 02:28:27,677 - freqtrade - INFO - freqtrade docker-2026.2-dev-f7b11c51
[entrypoint] Generating config.json with defaults...
2026-02-28 02:28:34,965 - freqtrade.configuration.deploy_config - INFO - Writing config to `/freqtrade/user_data/config.json`.
[entrypoint] Updating exchange to kraken...
[entrypoint] Switched exchange from binance to kraken
[entrypoint] First-time setup complete.
[entrypoint] Starting freqtrade...
2026-02-28 02:36:35,935 - freqtrade - INFO - freqtrade docker-2026.2-dev-f7b11c51
...
```

### Subsequent Starts

Once `config.json` exists, initialization is skipped:
```
[entrypoint] config.json found at /freqtrade/user_data/config.json. Skipping initialization.
[entrypoint] Starting freqtrade...
```

### Using Different Freqtrade Commands

Because the entrypoint is flexible, you can use it with any freqtrade subcommand:

**Run backtesting:**
```bash
docker compose -f docker-compose.yml run --rm freqtrade \
  python3 /entrypoint.py freqtrade backtesting --config user_data/config.json --strategy SampleStrategy
```

**Download data:**
```bash
docker compose -f docker-compose.yml run --rm freqtrade \
  python3 /entrypoint.py freqtrade download-data --config user_data/config.json --pairs BTC/USDT ETH/USDT
```

**Show configuration:**
```bash
docker compose -f docker-compose.yml run --rm freqtrade \
  python3 /entrypoint.py freqtrade show-config
```

The entrypoint script handles all of these—it initializes config if needed, then hands off to freqtrade with your requested command.

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
| `FREQTRADE_POSTGRES_USER` | PostgreSQL username | Local `.env` | Yes |
| `FREQTRADE_POSTGRES_PASSWORD` | PostgreSQL password | Local `.env` | Yes |
| `FREQTRADE_POSTGRES_DB` | PostgreSQL database name | Local `.env` | Yes |
| `FREQTRADE_API_USERNAME` | FreqUI login username | Local `.env` | Yes |
| `FREQTRADE_API_PASSWORD` | FreqUI login password | Local `.env` | Yes |
| `FREQTRADE_JWT_SECRET` | JWT token secret for API authentication | Local `.env` | Yes |
| `FREQTRADE_WS_TOKEN` | WebSocket token for real-time updates | Local `.env` | Yes |
| `FREQTRADE_TELEGRAM_ENABLED` | Enable/disable Telegram notifications | Local `.env` | No (defaults to false) |
| `FREQTRADE_TELEGRAM_TOKEN` | Telegram bot token from BotFather | Local `.env` | Only if Telegram enabled |
| `FREQTRADE_TELEGRAM_CHAT_ID` | Your Telegram chat ID for notifications | Local `.env` | Only if Telegram enabled |
| `DOMAIN` | Domain for Traefik routing | Global (root `.env`) | Yes |

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

Freqtrade can send real-time trade notifications via Telegram. To enable:

1. **Create a Telegram bot**:
   - Message [@BotFather](https://t.me/botfather) on Telegram
   - Use `/newbot` to create a new bot
   - Save the bot token provided

2. **Get your Telegram Chat ID**:
   - Message your bot
   - Visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   - Find your chat ID in the response

3. **Update `.env`**:
   ```dotenv
   FREQTRADE_TELEGRAM_ENABLED=true
   FREQTRADE_TELEGRAM_TOKEN=your_bot_token_here
   FREQTRADE_TELEGRAM_CHAT_ID=your_chat_id_here
   ```

4. **Restart the bot**:
   ```bash
   make down-freqtrade && make up-freqtrade
   ```

Available Telegram commands:
- `/start` - Start the bot
- `/stop` - Stop the bot
- `/status` - Show open trades
- `/profit` - Show profit/loss
- `/balance` - Show account balance
- `/forceexit <trade_id>` - Exit a specific trade
- `/help` - Show all commands

## Volumes & Networks

| Volume | Purpose | Type |
|--------|---------|------|
| `home_freqtrade_data` | User data directory (strategies, config, logs, data) | Named |
| `home_freqtrade_postgres_data` | PostgreSQL database storage | Named |

| Network | Purpose |
|---------|---------|
| `home_network` | External network for Traefik routing (FreqUI access) |
| `home_freqtrade_network` | Internal network for freqtrade ↔ PostgreSQL communication |

## Monitoring & Logs

### View Bot Logs

```bash
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml logs -f freqtrade
```

Or from the root folder:

```bash
docker logs -f freqtrade
```

### View Database Connection Logs

```bash
docker logs -f freqtrade_postgres
```

### Access REST API

```bash
# Login and get access token
curl -X POST --user freqtrader:yourpassword http://localhost:8080/api/v1/token/login

# Check bot health
curl http://localhost:8080/api/v1/health

# View open trades
curl http://localhost:8080/api/v1/trades
```

## Stopping and Restarting

### From the app folder:

```bash
# Stop
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml down

# Restart
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml down && \
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

### From the root folder:

```bash
# Stop
make down-freqtrade

# Restart
make down-freqtrade && make up-freqtrade
```

## Upgrading Freqtrade

```bash
# Pull the latest image
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml pull

# Restart with the new image
docker compose --env-file ../../.env --env-file .env -f docker-compose.yml up -d
```

Or use the root Makefile:

```bash
docker pull freqtradeorg/freqtrade:latest && make down-freqtrade && make up-freqtrade
```

## Database Backups

The PostgreSQL database automatically stores trade history, backtest results, and configuration. To backup:

```bash
# Export database
docker exec freqtrade_postgres pg_dump -U freqtrade freqtrade > freqtrade_backup.sql

# Restore from backup
docker exec -i freqtrade_postgres psql -U freqtrade freqtrade < freqtrade_backup.sql
```

## Troubleshooting

### Cannot connect to FreqUI

- Ensure Traefik is running: `make up-traefik` (or check root Makefile)
- Verify `DOMAIN` is set correctly in root `.env`
- Check bot is healthy: `docker logs freqtrade`
- Verify API server is enabled in logs

### Database Connection Failed

- Check PostgreSQL is healthy: `docker logs freqtrade_postgres`
- Verify credentials in `.env` match
- Ensure `home_freqtrade_network` exists: `docker network ls`
- Check database initialization logs: `docker logs freqtrade_postgres`

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
