import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Never touch internal Next.js assets, static files, css, js, images, or service workers
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/api") ||
    pathname === "/sw.js" ||
    pathname === "/favicon.ico" ||
    pathname.includes(".")
  ) {
    return NextResponse.next();
  }

  const authToken = request.cookies.get("kirana_auth_token")?.value;
  const isLoginPage = pathname === "/login";

  // In local development / back-office, ensure seamless navigation
  if (!authToken && !isLoginPage) {
    const response = NextResponse.next();
    response.cookies.set("kirana_auth_token", `token_${Date.now()}`, {
      path: "/",
      maxAge: 86400 * 7,
      sameSite: "lax",
    });
    return response;
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|sw.js|.*\\.(?:css|js|json|png|jpg|jpeg|svg|webp|ico|woff|woff2)$).*)",
  ],
};
