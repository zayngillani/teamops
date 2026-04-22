export async function getDayCommits(username: string, date: Date) {
  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    console.error("GITHUB_TOKEN is not set");
    return [];
  }

  const since = new Date(date);
  since.setHours(0, 0, 0, 0);
  
  const until = new Date(date);
  until.setHours(23, 59, 59, 999);

  try {
    const response = await fetch(
      `https://api.github.com/search/commits?q=author:${username}+committer-date:${since.toISOString().split('T')[0]}`,
      {
        headers: {
          Authorization: `token ${token}`,
          Accept: "application/vnd.github.cloak-preview",
        },
      }
    );

    const data = await response.json();
    return data.items || [];
  } catch (error) {
    console.error("Failed to fetch GitHub commits:", error);
    return [];
  }
}
