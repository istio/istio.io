export default async (request: Request, context) => {
  const url = new URL(request.url);
  const pathname = url.pathname;
  // Match version paths like /vX.XX/
  const versionMatch = pathname.match(/^\/v\d+\.\d+/);
  if (versionMatch) {
    // Define the main section paths that should be redirected
    const redirectableSections = ['/', '/about', '/blog', '/get-involved', '/news', '/search'];
    const versionPath = versionMatch[0]; // ex /v1.15
    const remainder = pathname.slice(versionPath.length) || '/';
    // Check if the remainder starts with a redirectable section
    const shouldRedirect = redirectableSections.some(section =>
      remainder === section || remainder.startsWith(`${section}/`) || (section === '/' && remainder === '')
    );
    if (shouldRedirect) {
      // Remove leading slash from remainder if it exists
      const cleanRemainder = remainder.startsWith('/') ? remainder.substring(1) : remainder;
      const newPath = `/latest/${cleanRemainder}`;
      return Response.redirect(new URL(newPath, url.origin), 301);
    }
    // For version-specific paths we want to keep, tell Netlify to stop processing this function
    return context.next();
  }
  // For all non-version paths, pass through
  return context.next();
};