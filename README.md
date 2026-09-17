# 非洲野生动物随身图鉴

单文件、零外部资源依赖的静态网页。127 张动物照片全部内嵌，支持搜索、国家与类群筛选、本地打卡、分类折叠和离线保存。

公开网址（推荐，中国大陆实测可访问）：

https://africa-wildlife-field-guide.pages.dev

Cloudflare Workers 镜像：

https://africa-wildlife-field-guide.695116763.workers.dev

## 本地预览

```powershell
pnpm install
pnpm dev
```

也可以直接双击 `public/index.html`。网页运行不需要网络，只有点击照片的 iNaturalist 来源链接时才需要网络。

## Cloudflare 自动发布

项目已通过 Cloudflare 的 GitHub App 连接仓库。推送到 `main` 分支后，会自动构建并发布 `public` 目录：

- GitHub 仓库：`xiaozhumenghuan/africa-wildlife-field-guide`
- 生产分支：`main`
- 构建输出目录：`public`
- 自动部署：已启用

Cloudflare Workers Static Assets 配置仍保留在 `wrangler.jsonc`，可手动执行：

```powershell
pnpm deploy
```

当前网络无法直接连接 GitHub Git 端口时，可使用仓库内脚本通过 GitHub REST API 同步：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish_github.ps1
```

## 图片来源

动物照片下载自 iNaturalist，并在每张卡片中保留摄影者、许可类型和来源观察记录。网页本身不依赖 iNaturalist 在线接口。
