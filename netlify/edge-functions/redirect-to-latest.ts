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
    // Check if the remainder starts with a language code
    const languageCodeMatch = remainder.match(/^\/([a-z]{2})\//);
    let languageCode: string | null = null;
    let sectionPath: string = remainder;

    if (languageCodeMatch) {
      languageCode = languageCodeMatch[1];
      sectionPath = remainder.slice(languageCodeMatch[0].length) || '/'; // slice to remove the leading slash of the language code
    }
    // Check if the base section (after removing language code) is redirectable
    const shouldRedirect = redirectableSections.some(section =>
      sectionPath === section || sectionPath.startsWith(`${section}/`) || (section === '/' && sectionPath === ''));

    if (shouldRedirect) {
      const cleanSectionPath = sectionPath.startsWith('/') ? sectionPath.substring(1) : sectionPath;
      const newPath = `/latest/${cleanSectionPath}`; // English path doesn't include language code
      return Response.redirect(new URL(newPath, url.origin), 301);
    }
    // For version-specific paths we want to keep, tell Netlify to stop processing this function
    return context.next();
  }
  // For all non-version paths, pass through
  return context.next();
};