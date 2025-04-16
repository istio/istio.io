export default async (request: Request, context) => {
  const url = new URL(request.url);
  let pathname = url.pathname;
  // Normalize pathname by removing consecutive slashes
  pathname = pathname.replace(/\/\/+/g, '/');
  // Match version paths like /vX.XX/
  const versionMatch = pathname.match(/^\/v\d+\.\d+/);

  if (versionMatch) {
    // Define the main section paths that should be redirected
    const redirectableSections = ['/', '/about', '/blog', '/get-involved', '/news', '/search'];
    const versionPath = versionMatch[0]; // ex /v1.15
    const remainder = pathname.slice(versionPath.length) || '/';
    // Check if the remainder starts with an optional leading slash followed by a language code
    const languageCodeMatch = remainder.match(/^\/?([a-z]{2})(\/|$)/);
    let languageCode: string | null = null;
    let remainingPathAfterLang = remainder;

    if (languageCodeMatch) {
      languageCode = languageCodeMatch[1];
      remainingPathAfterLang = remainder.slice(languageCodeMatch[0].length);
    }
    // If there's a language code and no further path, redirect to the homepage with the language code
    if (languageCode && remainingPathAfterLang === '') {
      return Response.redirect(new URL(`/latest/${languageCode}/`, url.origin), 301);
    }
    // Check if the remaining path (after version and optional language code) starts with a redirectable section
    const shouldRedirect = redirectableSections.some(section =>
      remainingPathAfterLang === section || remainingPathAfterLang.startsWith(`${section}/`) || (section === '/' && remainingPathAfterLang === ''));

    if (shouldRedirect) {
      const cleanRemainderPath = remainingPathAfterLang.startsWith('/') ? remainingPathAfterLang.substring(1) : remainingPathAfterLang;
      const newPath = `/latest/${languageCode ? `${languageCode}/` : ''}${cleanRemainderPath}`;
      return Response.redirect(new URL(newPath, url.origin), 301);
    }
    // For version-specific paths we want to keep, tell Netlify to stop processing this function
    return context.next();
  }
  // For all non-version paths, pass through
  return context.next();
};