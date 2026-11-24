# Hosting the Privacy Policy — Step-by-Step Options

## Option 1: GitHub Pages (Free, Recommended)

1. **Create a repo** (or use existing):
   ```bash
   git init tutordesk-privacy
   cd tutordesk-privacy
   cp ../tutordesk/privacy.html index.html
   ```

2. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Add privacy policy"
   git remote add origin https://github.com/<your-username>/tutordesk-privacy.git
   git push -u origin main
   ```

3. **Enable Pages**: Repo → Settings → Pages → Source: "Deploy from a branch" → Branch: `main` → Folder: `/ (root)` → Save.

4. **URL**: `https://<your-username>.github.io/tutordesk-privacy/`

---

## Option 2: Netlify (Free, Drag-and-Drop)

1. Go to https://app.netlify.com/drop
2. Drag the `privacy.html` file (rename to `index.html`) onto the page
3. Netlify gives you `https://<random-name>.netlify.app`
4. Optional: Set custom domain in Site settings

---

## Option 3: Your Own Domain (If You Have One)

1. Add `privacy.html` to your web root or a `/privacy/` folder
2. Configure your web server (Nginx/Apache/Vercel/Cloudflare Pages) to serve it at `/privacy`
3. Example Nginx:
   ```nginx
   location = /privacy {
       try_files /privacy.html =404;
   }
   ```

---

## What You Need to Do After I'm Done

### 1. Host the Privacy Policy (Pick One Above)
- Deploy `privacy.html` using Option 1, 2, or 3
- Note the final public URL (e.g., `https://yourname.github.io/tutordesk-privacy/`)

### 2. Update Play Console Listing
- Open Play Console → **TutorDesk** → **Store presence** → **Main store listing**
- Paste the privacy policy URL in the **Privacy policy** field
- Fill in the rest using `PLAY_STORE_METADATA.md`:
  - App title, short description, full description
  - Upload graphics (icon, feature graphic, screenshots)

### 3. Generate Screenshots (Required for Play Console)
Run the app locally and capture 5 phone screenshots:
```bash
cd tutordesk
npm run dev
# Open http://localhost:5173 in Chrome DevTools device toolbar (mobile view)
# Capture these screens:
# 1. Role selection screen (#roleScreen)
# 2. Calendar (#cal) with a few sessions
# 3. People/Students list (#people)
# 4. Invoices (#invoices) with sample data
# 5. Gradebook (#gradebook)
```
Save as PNG, 1080×1920 or similar (16:9 portrait).

### 4. Create Feature Graphic (1024×500)
- Can be a simple branded banner: "TutorDesk — Tutoring Management" on teal gradient
- Use Figma, Canva, or any design tool

### 5. Upload AAB to Play Console
- **Play Console** → **Release** → **Testing** → **Internal testing** → **Create release**
- Upload: `android/app/build/outputs/bundle/release/app-release.aab`
- Fill release notes, save, review, roll out to Internal Testing

### 6. Complete Content Rating Questionnaire
- Play Console → **Policy** → **App content** → **Content rating** → Start questionnaire
- Select "Education" category, answer questions (no violence, no user-generated content sharing, etc.)

### 7. Target API Level & Permissions
- Already set: `targetSdkVersion` in `android/build.gradle` (Capacitor handles this)
- Only `INTERNET` permission declared — no sensitive permissions

### 8. Submit for Review
- Once Internal Testing works, promote to **Closed** → **Open** → **Production**
- Review takes 1–7 days typically

---

## Files Ready in This Repo
| File | Purpose |
|------|---------|
| `privacy.html` | Privacy policy (deploy this) |
| `PLAY_STORE_METADATA.md` | Copy-paste listing text |
| `android/app/build/outputs/bundle/release/app-release.aab` | Signed release bundle |
| `android/app/keystore/tutordesk-release.keystore` | Keep secure — needed for future updates |

---

## Checklist
- [ ] Privacy policy hosted at public HTTPS URL
- [ ] Privacy policy URL entered in Play Console
- [ ] Store listing text filled (from `PLAY_STORE_METADATA.md`)
- [ ] 512×512 app icon uploaded
- [ ] 1024×500 feature graphic uploaded
- [ ] 5+ phone screenshots uploaded
- [ ] AAB uploaded to Internal Testing
- [ ] Content rating questionnaire completed
- [ ] Submit for review