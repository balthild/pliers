import { explainCronExpr } from '#/lib/cron/explain';

declare global {
	interface Window {
		explainCronExpr: typeof explainCronExpr;
	}
}

window.explainCronExpr = explainCronExpr;
