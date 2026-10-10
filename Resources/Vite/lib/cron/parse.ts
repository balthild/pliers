import type { FieldMeta } from './meta';

export interface Term {
	start: number;
	end: number;
	step: number;
}

/**
 * Parses one comma-separated term: `*`, `5`, `1-10`, `15/3`, `MON-FRI`, `10/5`.
 */
export function parseTerm(text: string, meta: FieldMeta): Term | null {
	const parts = text.split('/');
	if (parts.length > 2) return null;

	const rangeText: string = parts[0];
	const stepText: string | undefined = parts[1];

	let step = 1;
	if (stepText !== undefined) {
		if (!/^\d+$/.test(stepText)) return null;
		step = Number(stepText);
		if (step < 1) return null;
	}

	if (rangeText === '*') {
		return { start: meta.min, end: meta.max, step };
	}

	const bounds = rangeText.split('-');
	if (bounds.length > 2) return null;

	const startText: string = bounds[0];
	const endText: string | undefined = bounds[1];

	const start = parseValue(startText, meta);
	if (start === null) return null;

	if (endText === undefined) {
		// `a` (a single value) or `a/n` (a step from `a` up to the field maximum).
		const end = stepText === undefined ? start : meta.max;
		return { start, end, step };
	}

	const end = parseValue(endText, meta);
	if (end === null || end < start) return null;

	return { start, end, step };
}

function parseValue(text: string, meta: FieldMeta): number | null {
	const named = meta.names?.[text.toUpperCase()];
	if (named !== undefined) return named;

	if (!/^\d+$/.test(text)) return null;

	const value = Number(text);
	return value >= meta.min && value <= meta.max ? value : null;
}
