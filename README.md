# 非洲野生动物随身图鉴

单文件、零外部资源依赖的静态网页。127 张动物照片全部内嵌，支持搜索、国家与类群筛选、本地打卡、分类折叠和离线保存。

线上预览：https://africa-wildlife-field-guide.695116763.workers.dev

## 本地预览

```powershell
pnpm install
pnpm dev
```

也可以直接双击 `public/index.html`。网页运行不需要网络，只有点击照片的 iNaturalist 来源链接时才需要网络。

## Cloudflare Workers 自动发布

项目使用 Cloudflare Workers Static Assets，配置位于 `wrangler.jsonc`。

1. 在 Cloudflare 控制台创建 API Token，权限至少包含 `Workers Scripts: Edit` 和 `Account Settings: Read`。
2. 在 GitHub 仓库的 `Settings > Secrets and variables > Actions` 添加：
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`
3. 推送到 `main` 分支后，`.github/workflows/deploy.yml` 会自动部署。
4. 首次部署完成后，Cloudflare 会提供 `https://africa-wildlife-field-guide.<账户子域>.workers.dev` 公开网址。

也可以在 Cloudflare 控制台使用 `Workers & Pages > Create > Connect to Git` 连接同一仓库，构建命令填 `pnpm install`，部署命令填 `pnpm exec wrangler deploy`。

当前网络无法直接连接 GitHub Git 端口时，可使用仓库内脚本通过 GitHub REST API 同步：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github.ps1
```

## 图片来源

动物照片下载自 iNaturalist，并在每张卡片中保留摄影者、许可类型和来源观察记录。网页本身不依赖 iNaturalist 在线接口。
