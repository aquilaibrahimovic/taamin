// netlify/functions/imagekit-delete.js
const crypto = require("crypto");

exports.handler = async function (event) {
  try {
    if (event.httpMethod !== "POST") {
      return { statusCode: 405, body: "Method Not Allowed" };
    }

    const { fileId } = JSON.parse(event.body || "{}");
    if (!fileId) {
      return { statusCode: 400, body: JSON.stringify({ error: "Missing fileId" }) };
    }

    const privateKey = process.env.IMAGEKIT_PRIVATE_KEY;
    if (!privateKey) {
      return { statusCode: 500, body: JSON.stringify({ error: "Missing IMAGEKIT_PRIVATE_KEY" }) };
    }

    // ImageKit deletion API uses Basic Auth: <privateKey>:
    const auth = Buffer.from(`${privateKey}:`).toString("base64");

    const resp = await fetch(`https://api.imagekit.io/v1/files/${encodeURIComponent(fileId)}`, {
      method: "DELETE",
      headers: {
        Authorization: `Basic ${auth}`,
      },
    });

    const text = await resp.text();

    if (!resp.ok) {
      return {
        statusCode: resp.status,
        headers: { "Access-Control-Allow-Origin": "*" },
        body: JSON.stringify({ error: "ImageKit delete failed", details: text }),
      };
    }

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ ok: true }),
    };
  } catch (e) {
    return {
      statusCode: 500,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ error: String(e) }),
    };
  }
};