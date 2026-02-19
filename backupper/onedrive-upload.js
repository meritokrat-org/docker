// onedrive-upload.js
// Node.js 18+ (використовує built-in fetch)

const fs = require("fs");
const path = require("path");

const {
    CLIENT_ID,
    CLIENT_SECRET,
    REFRESH_TOKEN,
    TENANT_ID = "consumers", // для персонального OneDrive
} = process.env;

if (!CLIENT_ID || !CLIENT_SECRET || !REFRESH_TOKEN) {
    console.error("Set CLIENT_ID, CLIENT_SECRET, REFRESH_TOKEN in env");
    process.exit(1);
}

const [, , localFilePath, remotePathArg] = process.argv;
if (!localFilePath) {
    console.error('Usage: node onedrive-upload.js <localFilePath> [remotePathInOneDrive]');
    process.exit(1);
}
const remotePath = remotePathArg || path.basename(localFilePath);

async function refreshAccessToken() {
    const tokenUrl = `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`;
    const body = new URLSearchParams({
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        grant_type: "refresh_token",
        refresh_token: REFRESH_TOKEN,
        scope: "offline_access Files.ReadWrite User.Read",
    });

    const r = await fetch(tokenUrl, {
        method: "POST",
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body,
    });
    const json = await r.json();
    if (!r.ok) throw new Error(`Token refresh failed: ${r.status} ${JSON.stringify(json)}`);
    return json.access_token;
}

async function uploadSmall(accessToken, filePath, remotePathInDrive) {
    const data = await fs.promises.readFile(filePath);
    const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${encodeURI(remotePathInDrive)}:/content`;

    const r = await fetch(url, {
        method: "PUT",
        headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/octet-stream",
        },
        body: data,
    });

    const json = await r.json();
    if (!r.ok) throw new Error(`Small upload failed: ${r.status} ${JSON.stringify(json)}`);
    return json;
}

async function createUploadSession(accessToken, remotePathInDrive) {
    const url = `https://graph.microsoft.com/v1.0/me/drive/root:/${encodeURI(remotePathInDrive)}:/createUploadSession`;
    const r = await fetch(url, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            item: {
                "@microsoft.graph.conflictBehavior": "replace",
                name: path.basename(remotePathInDrive),
            },
        }),
    });

    const json = await r.json();
    if (!r.ok) throw new Error(`Create session failed: ${r.status} ${JSON.stringify(json)}`);
    return json.uploadUrl;
}

async function uploadLarge(accessToken, filePath, remotePathInDrive) {
    const uploadUrl = await createUploadSession(accessToken, remotePathInDrive);
    const stat = await fs.promises.stat(filePath);
    const fileSize = stat.size;
    const chunkSize = 10 * 1024 * 1024; // 10MB

    const fd = await fs.promises.open(filePath, "r");
    try {
        let start = 0;
        while (start < fileSize) {
            const end = Math.min(start + chunkSize, fileSize) - 1;
            const len = end - start + 1;
            const buffer = Buffer.alloc(len);
            await fd.read(buffer, 0, len, start);

            const r = await fetch(uploadUrl, {
                method: "PUT",
                headers: {
                    "Content-Length": String(len),
                    "Content-Range": `bytes ${start}-${end}/${fileSize}`,
                },
                body: buffer,
            });

            if (!(r.ok || r.status === 202 || r.status === 201)) {
                const text = await r.text();
                throw new Error(`Chunk upload failed: ${r.status} ${text}`);
            }

            start = end + 1;
            process.stdout.write(`\rUploaded ${Math.floor((start / fileSize) * 100)}%`);
        }
        process.stdout.write("\n");
    } finally {
        await fd.close();
    }
}

(async () => {
    try {
        const accessToken = await refreshAccessToken();
        const size = (await fs.promises.stat(localFilePath)).size;
        const limit = 250 * 1024 * 1024;

        if (size <= limit) {
            const res = await uploadSmall(accessToken, localFilePath, remotePath);
            console.log("Uploaded:", res.webUrl || res.id);
        } else {
            await uploadLarge(accessToken, localFilePath, remotePath);
            console.log("Uploaded large file:", remotePath);
        }
    } catch (e) {
        console.error(e.message || e);
        process.exit(1);
    }
})();