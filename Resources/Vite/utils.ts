export async function fetchJson(url: string, options: RequestInit = {}) {
	const request = new Request(url, options);
	request.headers.set('Accept', 'application/json');

	const response = await fetch(request);

	if (!response.ok) {
		const data = await response.json();
		throw new Error(data.reason ?? response.statusText);
	}

	if (response.status === 204) {
		return undefined;
	}

	return await response.json();
}
