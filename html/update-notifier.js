// caipora — aviso de nova versão (PWA).
//
// O service worker gerado pelo Godot serve o jogo do cache (cache-first) e o shell padrão
// não detecta atualizações: o SW novo fica "waiting" até todas as abas fecharem. Este script
// detecta o SW novo, mostra um banner discreto e, no clique, manda a mensagem 'update' — que
// o SW do Godot já implementa (skipWaiting + clients.claim + navigate), trocando para a versão
// nova e recarregando. Carregado via html/head_include (export_presets.cfg).

(function () {
	'use strict';

	if (!('serviceWorker' in navigator)) {
		return;
	}

	// Intervalo de checagem ativa para abas de vida longa (ms).
	var UPDATE_POLL_MS = 60000;

	var reloaded = false;        // guarda contra reload duplo
	var bannerEl = null;
	var labelEl = null;

	// ─── Banner ────────────────────────────────────────
	function buildBanner() {
		if (bannerEl) {
			return;
		}
		var bar = document.createElement('div');
		bar.id = 'caipora-update-banner';
		bar.style.cssText = [
			'position:fixed',
			'top:0',
			'left:0',
			'right:0',
			'z-index:99999',
			// Respeita o notch/safe-area no topo (iPhone/Android).
			'padding:calc(env(safe-area-inset-top, 0px) + 10px) 16px 10px 16px',
			'display:flex',
			'align-items:center',
			'justify-content:center',
			'gap:14px',
			'flex-wrap:wrap',
			'background:#0d1117',
			'border-bottom:2px solid #8b0000',
			'box-shadow:0 2px 12px rgba(0,0,0,0.6)',
			"font-family:'Noto Sans','Droid Sans',Arial,sans-serif",
			'font-size:14px',
			'color:#c9d1d9',
			'transform:translateY(-110%)',
			'transition:transform 0.35s ease-out',
		].join(';');

		labelEl = document.createElement('span');
		labelEl.textContent = 'Nova versão disponível';
		bar.appendChild(labelEl);

		var updateBtn = document.createElement('button');
		updateBtn.textContent = 'Atualizar';
		updateBtn.style.cssText = [
			'background:#8b0000',
			'color:#fff',
			'border:0',
			'border-radius:4px',
			'padding:6px 16px',
			'font-size:14px',
			'font-weight:600',
			'cursor:pointer',
		].join(';');
		updateBtn.addEventListener('click', applyUpdate);
		bar.appendChild(updateBtn);

		var laterBtn = document.createElement('a');
		laterBtn.textContent = 'depois';
		laterBtn.href = '#';
		laterBtn.style.cssText = 'color:#8b949e;text-decoration:underline;cursor:pointer';
		laterBtn.addEventListener('click', function (e) {
			e.preventDefault();
			hideBanner();
		});
		bar.appendChild(laterBtn);

		document.body.appendChild(bar);
		bannerEl = bar;
	}

	function showBanner() {
		buildBanner();
		// Tenta enriquecer o texto com o número da versão nova (rede, fora do cache do SW).
		fetch('version.json', { cache: 'no-store' })
			.then(function (r) { return r.ok ? r.json() : null; })
			.then(function (info) {
				if (info && info.version && labelEl) {
					labelEl.textContent = 'Nova versão disponível (' + info.version + ')';
				}
			})
			.catch(function () { /* banner genérico já basta */ });
		// força reflow antes de animar a entrada
		void bannerEl.offsetWidth;
		bannerEl.style.transform = 'translateY(0)';
	}

	function hideBanner() {
		if (bannerEl) {
			bannerEl.style.transform = 'translateY(-110%)';
		}
	}

	// ─── Update ────────────────────────────────────────
	function applyUpdate() {
		navigator.serviceWorker.getRegistration().then(function (reg) {
			if (reg && reg.waiting) {
				// O handler 'update' do SW do Godot faz skipWaiting + claim + navigate.
				reg.waiting.postMessage('update');
			} else {
				// Sem worker em espera: recarrega como fallback simples.
				safeReload();
			}
		});
	}

	function safeReload() {
		if (reloaded) {
			return;
		}
		reloaded = true;
		window.location.reload();
	}

	// ─── Detecção ──────────────────────────────────────
	function watchRegistration(reg) {
		if (!reg) {
			return;
		}
		// Já existe um worker em espera (deploy aconteceu antes de carregarmos).
		if (reg.waiting && navigator.serviceWorker.controller) {
			showBanner();
		}
		reg.addEventListener('updatefound', function () {
			var installing = reg.installing;
			if (!installing) {
				return;
			}
			installing.addEventListener('statechange', function () {
				// 'installed' + já havia um controller ⇒ é update (não primeira instalação).
				if (installing.state === 'installed' && navigator.serviceWorker.controller) {
					showBanner();
				}
			});
		});

		// Checagem ativa: agora, ao focar a aba, e periodicamente.
		var check = function () { reg.update().catch(function () {}); };
		check();
		document.addEventListener('visibilitychange', function () {
			if (document.visibilityState === 'visible') {
				check();
			}
		});
		window.addEventListener('focus', check);
		setInterval(check, UPDATE_POLL_MS);
	}

	// O engine do Godot registra o SW durante startGame; navigator.serviceWorker.ready
	// resolve quando há um SW ativo, sem precisarmos registrar nós mesmos.
	navigator.serviceWorker.ready.then(watchRegistration).catch(function () {});

	function start() {
		// Garante <body> pronto para anexar o banner quando necessário (defer já adia,
		// mas o guard mantém robusto se o script for movido).
	}
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', start);
	} else {
		start();
	}
}());
