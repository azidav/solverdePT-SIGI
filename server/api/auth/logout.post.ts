export default defineEventHandler(async (event) => {
  // Clear cookie by setting it with Max-Age=0
  const cookieStr = `auth.token=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0`;
  event.node.res.setHeader('Set-Cookie', cookieStr);
  return { ok: true };
});
