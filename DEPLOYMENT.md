# Gate-WireGuard Production Deployment Guide

## 🎉 Congratulations! Your application is ready for production!

## Prerequisites
- Ubuntu/Debian server with root access
- Domain name (optional but recommended for SSL)
- At least 2GB RAM and 20GB disk space

## Quick Deployment

### 1. Automated Deployment (Recommended)
```bash
sudo ./deploy.sh
```

### 2. Manual Configuration After Deployment

#### Update Environment Variables
Edit `.env.production`:
```bash
nano .env.production
```

Required values:
- `DATABASE_URL`: Update with your MySQL password
- `GOOGLE_CLIENT_ID`: Your Google OAuth client ID
- `GOOGLE_CLIENT_SECRET`: Your Google OAuth client secret
- `SECRET_KEY_BASE`: Generated automatically

#### Update Google OAuth Settings
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services > Credentials
3. Update your OAuth 2.0 client with:
   - Authorized JavaScript origins: `https://your-domain.com`
   - Authorized redirect URIs: `https://your-domain.com/auth/google_oauth2/callback`

#### Restart Services
```bash
sudo systemctl restart gate-wireguard
sudo systemctl restart nginx
```

## Service Management

### Check Application Status
```bash
sudo systemctl status gate-wireguard
```

### View Application Logs
```bash
sudo journalctl -u gate-wireguard -f
```

### Restart Application
```bash
sudo systemctl restart gate-wireguard
```

## SSL Setup (Highly Recommended)
```bash
sudo certbot --nginx -d your-domain.com
```

## Database Backup
```bash
mysqldump -u root -p gate_wireguard_production > backup_$(date +%Y%m%d).sql
```

## Application Updates
```bash
cd /home/ajey/workspace/gate-wireguard
git pull origin main
bundle install --deployment --without development test
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails assets:precompile
sudo systemctl restart gate-wireguard
```

## WireGuard Server Configuration

After deployment, configure WireGuard through the admin panel:

1. Access your application at `https://your-domain.com`
2. Sign in with Google OAuth
3. Go to Admin > Settings
4. Configure WireGuard server settings:
   - Server IP range (e.g., 10.0.0.0/24)
   - DNS servers
   - Port (default: 51820)

## Monitoring & Maintenance

### System Resources
```bash
htop
df -h
free -h
```

### Application Performance
- Monitor logs: `sudo journalctl -u gate-wireguard -f`
- Check database: `mysql -u root -p gate_wireguard_production`

### Security Updates
```bash
sudo apt update && sudo apt upgrade -y
sudo systemctl restart gate-wireguard
```

## Troubleshooting

### Common Issues

1. **Application won't start**
   - Check logs: `sudo journalctl -u gate-wireguard -f`
   - Verify environment variables in `.env.production`
   - Check database connection

2. **Assets not loading**
   - Recompile assets: `RAILS_ENV=production bundle exec rails assets:precompile`
   - Check Nginx configuration

3. **Database connection errors**
   - Verify MySQL is running: `sudo systemctl status mysql`
   - Check database credentials in `.env.production`

4. **Google OAuth not working**
   - Verify redirect URIs in Google Cloud Console
   - Check client ID and secret in `.env.production`

### Log Locations
- Application logs: `/home/ajey/workspace/gate-wireguard/log/production.log`
- Nginx logs: `/var/log/nginx/`
- System logs: `journalctl -u gate-wireguard`

## Support
For issues, check the application logs and system status first. The backup system you implemented allows for easy data recovery if needed.

---

**🚀 Your Gate-WireGuard VPN Management System is now production-ready!**