# Профили DeepSeek Harness (R8.6, ПРОВЕРИТЬ)

Роль «альтернативный автономный» (AI_SUBSYSTEM.md §3.4, AI-AGT-1) на `dsh`.
`$DSH_HOME` (= `~/.config/deepseek-harness`, agent-launcher) требует профиль
под `profiles/<имя>`; схема профиля (провайдер, модель-роль `cost-autonomous`,
ключ доступа к `llm-gateway`) — dev preview без стабильного релиза, формат не
подтверждён. Проверить `dsh --dump-config-schema` и `dsh --from-default-profile
web` на реальном хосте, затем описать здесь конкретный профиль (не раньше).
