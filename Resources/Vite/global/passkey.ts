import { fetchJson } from '#/lib/utils';

declare global {
	interface Window {
		passkeyCreate: (name: string) => Promise<void>;
		passkeyLogin: () => Promise<void>;
	}
}

window.passkeyCreate = async (name: string) => {
	const options = await fetchJson('/settings/passkey');
	const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(options.publicKey);

	const passkey = await navigator.credentials.create({ publicKey });

	await fetchJson('/settings/passkey', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ name, passkey }),
	});

	location.reload();
};

window.passkeyLogin = async () => {
	const options = await fetchJson('/login/passkey');
	const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(options.publicKey);

	const passkey = await navigator.credentials.get({ publicKey });

	await fetchJson('/login/passkey', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ passkey }),
	});

	location.assign('/');
};
