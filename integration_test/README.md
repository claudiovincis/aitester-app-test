# AITester - Integration Tests

## Flow Replay Tests

Gli integration test in `integration_test/flow_replay_test.dart` dimostrano il replay automatico dei flussi utente.

### Test disponibili

1. **Replay crash flow from server logs**: Login base e verifica navigazione
2. **Replay full crash sequence**: Simula il percorso completo che porta al crash
3. **Fetch and replay flow from server API**: Legge eventi dal server e li replica automaticamente

### Esecuzione

```powershell
# Esegui tutti gli integration test
& "C:\Users\claud\OneDrive\Documenti\Flutter\flutter\bin\flutter.bat" test integration_test/flow_replay_test.dart

# Esegui con sessionId specifico dal server
& "C:\Users\claud\OneDrive\Documenti\Flutter\flutter\bin\flutter.bat" test integration_test/flow_replay_test.dart --dart-define=TEST_SESSION_ID=<your-session-guid>
```

### Workflow completo crash -> replay -> fix

1. Avvia server: `dotnet run --project server/AITester.Server.Presentation`
2. Avvia agent: `dotnet run --project agent/AITester.Agent.Worker`
3. Esegui app Flutter manualmente o con test integration
4. Quando si verifica crash, ottieni il `sessionId` dal log
5. Trigger orchestrator: `Invoke-RestMethod -Method Post -Uri "http://localhost:5000/api/orchestrator/crash-trigger/<CRASH_ID>"`
6. Agent legge il crash, chiama Ollama per analisi, salva risultati
7. Riesegui integration test con il sessionId per verificare se il fix funziona

### Note

- I test richiedono che il server sia in esecuzione su `localhost:5000`
- Il terzo test (`Fetch and replay flow from server API`) richiede un `TEST_SESSION_ID` valido
- Il crash è intenzionale nella `CrashView` quando `_enableCrash = true`
