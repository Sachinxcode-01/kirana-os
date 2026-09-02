import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Never touch internal Next.js assets, static files, css, js, images, or fonts
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/api") ||
    pathname.includes(".")
  ) {
    return NextResponse.next();
  }

  const authToken = request.cookies.get("kirana_auth_token")?.value;
  const isLoginPage = pathname === "/login";

  // If unauthenticated and trying to access back-office routes, redirect to /login
  if (!authToken && !isLoginPage) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // If already authenticated and visiting /login, redirect to /
  if (authToken && isLoginPage) {
    return NextResponse.redirect(new URL("/", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:css|js|json|png|jpg|jpeg|svg|webp|ico|woff|woff2)$).*)",
  ],
};
