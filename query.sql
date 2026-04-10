
public async Task<bool> RunningAsync()
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    LogInfo(nameof(RunningAsync), "ENTER");

    try
    {
        using (var socket = await ConnectWithTimeoutAsync(RobotIp, SocketPort, 1500))
        {
            var stream = socket.GetStream();

            string response = await ReceiveAsync(stream);
            LogDebug(nameof(RunningAsync), $"Welcome={response}");

            await SendAsync(stream, "running\n");
            response = await ReceiveAsync(stream);

            LogInfo(nameof(RunningAsync), $"Response={response}");

            if (response.Trim() == "Program running: true")
            {
                LogInfo(nameof(RunningAsync), $"EXIT result=true elapsed={sw.ElapsedMilliseconds}ms");
                return true;
            }

            if (response.Trim() == "Program running: false")
            {
                LogInfo(nameof(RunningAsync), $"EXIT result=false elapsed={sw.ElapsedMilliseconds}ms");
                return false;
            }

            throw new Exception("Risposta non riconosciuta: " + response);
        }
    }
    catch (Exception ex)
    {
        LogError(nameof(RunningAsync), $"FAIL elapsed={sw.ElapsedMilliseconds}ms", ex);
        throw;
    }
}

dashboard
private void LogInfo(string method, string message) =>
    FileLogger.Info($"Dashboard.{method}", message);

private void LogWarn(string method, string message) =>
    FileLogger.Warn($"Dashboard.{method}", message);

private void LogError(string method, string message, Exception ex = null) =>
    FileLogger.Error($"Dashboard.{method}", message, ex);


public Dashboard(Login FrmLogin, string[] _DataAccess)
{
    LogInfo(nameof(Dashboard), "ENTER costruttore Dashboard");

    InitializeComponent();
    CloseFormWMessageBox(FrmLogin);
    this.Shown += Dashboard_Shown;
    InitializePanel();

    RobotController.Instance.ModbusConnectionChanged += connected =>
    {
        LogInfo(nameof(Dashboard), $"Evento ModbusConnectionChanged connected={connected}");

        this.BeginInvoke(new Action(() =>
        {
            if (!connected)
            {
                LogWarn(nameof(Dashboard), "Robot DISCONNESSO (Modbus)");
                MostraErrore($"{DateTime.Now:HH:mm:ss} - Robot DISCONNESSO (Modbus).");
            }
            else
            {
                LogInfo(nameof(Dashboard), "Robot connesso.");
                MostraErrore($"{DateTime.Now:HH:mm:ss} - Robot connesso.");
            }
        }));
    };

    LogInfo(nameof(Dashboard), "EXIT costruttore Dashboard");
}


private async Task OnRobotAsync()
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    LogInfo(nameof(OnRobotAsync), "ENTER");

    try
    {
        MostraErrore("Connessione robot...");
        LogInfo(nameof(OnRobotAsync), "Messaggio UI: Connessione robot...");

        var accensioneOk = await RunWithTimeoutAsync(
            () => RobotController.Instance.AccendiRobotAsync(),
            3000,
            "AccendiRobot");

        LogInfo(nameof(OnRobotAsync), $"AccendiRobot result ok={accensioneOk.ok} error={accensioneOk.error}");

        if (!accensioneOk.ok)
        {
            MostraErrore($"{DateTime.Now:HH:mm:ss}: {accensioneOk.error}");
            LogWarn(nameof(OnRobotAsync), $"EXIT FAIL su AccendiRobot elapsed={sw.ElapsedMilliseconds}ms");
            return;
        }

        RobotController.Instance.StartPolling();
        LogInfo(nameof(OnRobotAsync), "Polling avviato");

        bool isRunning = await WithTimeoutBool(
            () => RobotController.Instance.RunningAsync(),
            3000,
            "RunningAsync");

        LogInfo(nameof(OnRobotAsync), $"RunningAsync result isRunning={isRunning}");

        if (isRunning)
        {
            BtnPausePlay.Text = "PAUSE";
            BtnPausePlay.BackgroundColor = Color.FromArgb(240, 173, 78);
            BtnPausePlay.ForeColor = Color.White;
            btnState = BtnState.PAUSE;
            LogInfo(nameof(OnRobotAsync), "UI aggiornata: stato PAUSE");
        }

        bool modbusConnected = RobotController.Instance.IsModbusConnected();
        LogInfo(nameof(OnRobotAsync), $"IsModbusConnected={modbusConnected}");

        if (!modbusConnected)
        {
            MostraErrore("Modbus non connesso.");
            LogWarn(nameof(OnRobotAsync), $"EXIT FAIL Modbus non connesso elapsed={sw.ElapsedMilliseconds}ms");
            return;
        }

        var writeAccensioneOk = await RunWithTimeoutAsync(
            () => RobotController.Instance.WriteRegister(128, 123),
            1500,
            "WriteRegister(128,123)");

        LogInfo(nameof(OnRobotAsync), $"WriteRegister(128,123) ok={writeAccensioneOk.ok} error={writeAccensioneOk.error}");

        if (!writeAccensioneOk.ok)
        {
            MostraErrore($"{DateTime.Now:HH:mm:ss}: {writeAccensioneOk.error}");
            LogWarn(nameof(OnRobotAsync), $"EXIT FAIL writeAccensioneOk elapsed={sw.ElapsedMilliseconds}ms");
            return;
        }

        var readAccensioneOk = await RunWithTimeoutAsync(
            () =>
            {
                var r = RobotController.Instance.ReadRegister(Registers.REG_Accensione);
                if (r == null || r.Length == 0)
                    throw new Exception("ReadRegister(REG_Accensione) non ha risposto.");
            },
            1500,
            "ReadRegister(REG_Accensione)");

        LogInfo(nameof(OnRobotAsync), $"ReadRegister(REG_Accensione) ok={readAccensioneOk.ok} error={readAccensioneOk.error}");

        if (!readAccensioneOk.ok)
        {
            MostraErrore($"{DateTime.Now:HH:mm:ss}: {readAccensioneOk.error}");
            LogWarn(nameof(OnRobotAsync), $"EXIT FAIL readAccensioneOk elapsed={sw.ElapsedMilliseconds}ms");
            return;
        }

        var programmaOk = await RunWithTimeoutAsync(
            () => RobotController.Instance.OttieniProgrammaCaricatoAsync(),
            1500,
            "OttieniProgrammaCaricato");

        LogInfo(nameof(OnRobotAsync), $"OttieniProgrammaCaricato ok={programmaOk.ok} error={programmaOk.error}");

        if (!programmaOk.ok)
        {
            MostraErrore($"{DateTime.Now:HH:mm:ss}: {programmaOk.error}");
            LogWarn(nameof(OnRobotAsync), $"EXIT FAIL programmaOk elapsed={sw.ElapsedMilliseconds}ms");
            return;
        }

        var resetRegistriOk = await RunWithTimeoutAsync(
            () =>
            {
                for (ushort i = 130; i <= 169; i++)
                {
                    if (i != 139 && i != 149 && i != 159 && i != 169)
                    {
                        LogInfo(nameof(OnRobotAsync), $"Reset registro i={i}");
                        RobotController.Instance.WriteRegister(i, 0);
                    }
                }
            },
            3000,
            "Reset registri 130-169");

        LogInfo(nameof(OnRobotAsync), $"Reset registri ok={resetRegistriOk.ok} error={resetRegistriOk.error}");

        if (!resetRegistriOk.ok)
        {
            MostraErrore($"{DateTime.Now:HH:mm:ss}: {resetRegistriOk.error}");
            LogWarn(nameof(OnRobotAsync), $"EXIT FAIL resetRegistriOk elapsed={sw.ElapsedMilliseconds}ms");
            return;
        }

        MostraErrore("");
        LogInfo(nameof(OnRobotAsync), $"EXIT OK elapsed={sw.ElapsedMilliseconds}ms");
    }
    catch (Exception ex)
    {
        LogError(nameof(OnRobotAsync), $"FAIL elapsed={sw.ElapsedMilliseconds}ms", ex);
        MostraErrore("Errore robot: " + ex.Message);
    }
}



private async Task<(bool ok, string error)> RunWithTimeoutAsync(Action action, int msTimeout, string operationName)
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    LogInfo(nameof(RunWithTimeoutAsync), $"ENTER operation={operationName} timeout={msTimeout}ms [Action]");

    try
    {
        var task = Task.Run(() =>
        {
            LogDebug(nameof(RunWithTimeoutAsync), $"TASK START operation={operationName} [Action]");
            action();
            LogDebug(nameof(RunWithTimeoutAsync), $"TASK END operation={operationName} [Action]");
        });

        var completed = await Task.WhenAny(task, Task.Delay(msTimeout));

        if (completed != task)
        {
            LogWarn(nameof(RunWithTimeoutAsync), $"TIMEOUT operation={operationName} elapsed={sw.ElapsedMilliseconds}ms [Action]");
            return (false, $"Timeout in {operationName} dopo {sw.ElapsedMilliseconds} ms");
        }

        await task;

        LogInfo(nameof(RunWithTimeoutAsync), $"EXIT OK operation={operationName} elapsed={sw.ElapsedMilliseconds}ms [Action]");
        return (true, null);
    }
    catch (Exception ex)
    {
        LogError(nameof(RunWithTimeoutAsync), $"EXIT FAIL operation={operationName} elapsed={sw.ElapsedMilliseconds}ms [Action]", ex);
        return (false, $"{operationName}: {ex.Message}");
    }
}


private async Task<(bool ok, string error)> RunWithTimeoutAsync(Func<Task> action, int msTimeout, string operationName)
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    LogInfo(nameof(RunWithTimeoutAsync), $"ENTER operation={operationName} timeout={msTimeout}ms [Func<Task>]");

    try
    {
        var task = action();
        var completed = await Task.WhenAny(task, Task.Delay(msTimeout));

        if (completed != task)
        {
            LogWarn(nameof(RunWithTimeoutAsync), $"TIMEOUT operation={operationName} elapsed={sw.ElapsedMilliseconds}ms [Func<Task>]");
            return (false, $"Timeout in {operationName} dopo {sw.ElapsedMilliseconds} ms");
        }

        await task;

        LogInfo(nameof(RunWithTimeoutAsync), $"EXIT OK operation={operationName} elapsed={sw.ElapsedMilliseconds}ms [Func<Task>]");
        return (true, null);
    }
    catch (Exception ex)
    {
        LogError(nameof(RunWithTimeoutAsync), $"EXIT FAIL operation={operationName} elapsed={sw.ElapsedMilliseconds}ms [Func<Task>]", ex);
        return (false, $"{operationName}: {ex.Message}");
    }
}


private async Task<bool> WithTimeoutBool(Func<Task<bool>> action, int msTimeout, string nomeOperazione)
{
    var sw = System.Diagnostics.Stopwatch.StartNew();
    LogInfo(nameof(WithTimeoutBool), $"ENTER operation={nomeOperazione} timeout={msTimeout}ms");

    try
    {
        var task = action();
        var completed = await Task.WhenAny(task, Task.Delay(msTimeout));

        if (completed != task)
        {
            LogWarn(nameof(WithTimeoutBool), $"TIMEOUT operation={nomeOperazione} elapsed={sw.ElapsedMilliseconds}ms");
            return false;
        }

        bool result = await task;
        LogInfo(nameof(WithTimeoutBool), $"EXIT operation={nomeOperazione} result={result} elapsed={sw.ElapsedMilliseconds}ms");
        return result;
    }
    catch (Exception ex)
    {
        LogError(nameof(WithTimeoutBool), $"FAIL operation={nomeOperazione} elapsed={sw.ElapsedMilliseconds}ms", ex);
        return false;
    }
}
