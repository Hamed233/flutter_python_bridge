package com.example.flutter_python_bridge;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.chaquo.python.PyException;
import com.chaquo.python.PyObject;
import com.chaquo.python.Python;
import com.chaquo.python.android.AndroidPlatform;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

/** FlutterPythonBridgePlugin */
public class FlutterPythonBridgePlugin implements FlutterPlugin, MethodCallHandler {
  private MethodChannel channel;
  private Python python;
  private boolean pythonInitialized = false;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_python_bridge");
    channel.setMethodCallHandler(this);
    
    // Initialize Python if possible
    try {
      if (!Python.isStarted()) {
        Python.start(new AndroidPlatform(flutterPluginBinding.getApplicationContext()));
      }
      python = Python.getInstance();
      pythonInitialized = true;
    } catch (Exception e) {
      pythonInitialized = false;
    }
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (!pythonInitialized) {
      try {
        python = Python.getInstance();
        pythonInitialized = true;
      } catch (Exception e) {
        result.error("PYTHON_ERROR", "Failed to initialize Python: " + e.getMessage(), null);
        return;
      }
    }
    
    switch (call.method) {
      case "isPythonAvailable":
        result.success(pythonInitialized);
        break;
      case "getPythonVersion":
        if (!pythonInitialized) {
          result.success(null);
          return;
        }
        try {
          PyObject sys = python.getModule("sys");
          String version = sys.get("version").toString();
          result.success(version);
        } catch (Exception e) {
          result.success(null);
        }
        break;
      case "runPythonCode":
        if (!pythonInitialized) {
          Map<String, Object> errorResult = new HashMap<>();
          errorResult.put("success", false);
          errorResult.put("error", "Python is not initialized");
          result.success(errorResult);
          return;
        }
        
        String code = call.argument("code");
        if (code == null || code.isEmpty()) {
          Map<String, Object> errorResult = new HashMap<>();
          errorResult.put("success", false);
          errorResult.put("error", "Python code is empty");
          result.success(errorResult);
          return;
        }
        
        try {
          // Simple direct approach - execute the code in the main module
          PyObject mainModule = python.getModule("__main__");
          PyObject globals = mainModule.get("__dict__");
          
          // Make sure math and other modules are available
          try {
            python.getModule("math");
          } catch (PyException e) {
            // If math module is not available, import it
            python.getBuiltins().get("exec").call("import math", globals);
          }
          
          // Also import other common modules
          String commonImports = "import datetime\nimport json\nimport sys\nimport os";
          python.getBuiltins().get("exec").call(commonImports, globals);
          
          // Capture stdout
          python.getBuiltins().get("exec").call(
              "import sys\n" +
              "import io\n" +
              "_stdout = sys.stdout\n" +
              "sys.stdout = io.StringIO()\n", globals);
          
          // Execute the user's code
          try {
            python.getBuiltins().get("exec").call(code, globals);
            
            // Get the captured output
            PyObject stdout = python.getBuiltins().get("eval").call("sys.stdout.getvalue()", globals);
            String output = stdout != null ? stdout.toString() : "";
            
            // Restore stdout
            python.getBuiltins().get("exec").call("sys.stdout = _stdout", globals);
            
            // Try to get the last expression's value
            PyObject returnValue = null;
            String[] lines = code.split("\n");
            for (int i = lines.length - 1; i >= 0; i--) {
              String line = lines[i].trim();
              if (!line.isEmpty() && !line.startsWith("#")) {
                try {
                  returnValue = python.getBuiltins().get("eval").call(line, globals);
                  break;
                } catch (PyException e) {
                  // Not a valid expression, ignore
                }
              }
            }
            
            Map<String, Object> successResult = new HashMap<>();
            successResult.put("success", true);
            successResult.put("output", output);
            successResult.put("return_value", returnValue != null ? returnValue.toString() : "");
            result.success(successResult);
          } catch (PyException e) {
            // Restore stdout even if there's an error
            try {
              python.getBuiltins().get("exec").call("sys.stdout = _stdout", globals);
            } catch (Exception ignored) {}
            
            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("success", false);
            errorResult.put("error", e.getMessage());
            result.success(errorResult);
          }
        } catch (Exception e) {
          Map<String, Object> errorResult = new HashMap<>();
          errorResult.put("success", false);
          errorResult.put("error", e.getMessage());
          result.success(errorResult);
        }
        break;
      case "runPythonScript":
        if (!pythonInitialized) {
          Map<String, Object> errorResult = new HashMap<>();
          errorResult.put("success", false);
          errorResult.put("error", "Python is not initialized");
          result.success(errorResult);
          return;
        }
        
        String scriptPath = call.argument("scriptPath");
        if (scriptPath == null || scriptPath.isEmpty()) {
          Map<String, Object> errorResult = new HashMap<>();
          errorResult.put("success", false);
          errorResult.put("error", "Script path is empty");
          result.success(errorResult);
          return;
        }
        
        try {
          // Check if the script file exists
          File scriptFile = new File(scriptPath);
          if (!scriptFile.exists()) {
            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("success", false);
            errorResult.put("error", "Script file does not exist: " + scriptPath);
            result.success(errorResult);
            return;
          }
          
          // Simple direct approach - execute the script in the main module
          PyObject mainModule = python.getModule("__main__");
          PyObject globals = mainModule.get("__dict__");
          
          // Make sure math and other modules are available
          try {
            python.getModule("math");
          } catch (PyException e) {
            // If math module is not available, import it
            python.getBuiltins().get("exec").call("import math", globals);
          }
          
          // Also import other common modules
          String commonImports = "import datetime\nimport json\nimport sys\nimport os";
          python.getBuiltins().get("exec").call(commonImports, globals);
          
          // Add the script directory to sys.path
          String scriptDir = scriptFile.getParent();
          python.getBuiltins().get("exec").call(
              "import sys\n" +
              "sys.path.insert(0, '" + scriptDir.replace("'", "\\'") + "')\n", globals);
          
          // Capture stdout
          python.getBuiltins().get("exec").call(
              "import sys\n" +
              "import io\n" +
              "_stdout = sys.stdout\n" +
              "sys.stdout = io.StringIO()\n", globals);
          
          // Read and execute the script
          try {
            // Read the file content
            PyObject builtins = python.getBuiltins();
            PyObject open = builtins.get("open");
            PyObject file = open.call(scriptPath, "r");
            String scriptContent = file.callAttr("read").toString();
            file.callAttr("close");
            
            // Execute the script content
            builtins.get("exec").call(scriptContent, globals);
            
            // Get the captured output
            PyObject stdout = builtins.get("eval").call("sys.stdout.getvalue()", globals);
            String output = stdout != null ? stdout.toString() : "";
            
            // Restore stdout
            builtins.get("exec").call("sys.stdout = _stdout", globals);
            
            Map<String, Object> successResult = new HashMap<>();
            successResult.put("success", true);
            successResult.put("output", output);
            successResult.put("return_value", ""); // Scripts typically don't return values
            result.success(successResult);
          } catch (PyException e) {
            // Restore stdout even if there's an error
            try {
              python.getBuiltins().get("exec").call("sys.stdout = _stdout", globals);
            } catch (Exception ignored) {}
            
            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("success", false);
            errorResult.put("error", e.getMessage());
            result.success(errorResult);
          }
        } catch (Exception e) {
          Map<String, Object> errorResult = new HashMap<>();
          errorResult.put("success", false);
          errorResult.put("error", e.getMessage());
          result.success(errorResult);
        }
        break;
      case "installPythonPackage":
        installPythonPackage(call.argument("packageName"), result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void installPythonPackage(String packageName, Result result) {
    if (packageName == null || packageName.isEmpty()) {
      Map<String, Object> errorResult = new HashMap<>();
      errorResult.put("success", false);
      errorResult.put("error", "Package name is empty");
      result.success(errorResult);
      return;
    }
    
    try {
      // Get the main module and globals
      PyObject mainModule = python.getModule("__main__");
      PyObject globals = mainModule.get("__dict__");
      
      // Capture stdout
      python.getBuiltins().get("exec").call(
          "import sys\n" +
          "import io\n" +
          "_stdout = sys.stdout\n" +
          "_stderr = sys.stderr\n" +
          "sys.stdout = io.StringIO()\n" +
          "sys.stderr = io.StringIO()\n", globals);
      
      // Try to import pip
      try {
        python.getModule("pip");
      } catch (PyException e) {
        // If pip is not available, try to install it
        python.getBuiltins().get("exec").call(
            "import ensurepip\n" +
            "ensurepip.bootstrap()\n", globals);
      }
      
      // Install the package using pip
      python.getBuiltins().get("exec").call(
          "import pip\n" +
          "import subprocess\n" +
          "try:\n" +
          "    from pip._internal import main as pip_main\n" +
          "except ImportError:\n" +
          "    from pip import main as pip_main\n" +
          "\n" +
          "try:\n" +
          "    pip_main(['install', '" + packageName.replace("'", "\\'" ) + "'])\n" +
          "except:\n" +
          "    # Fallback to subprocess if pip_main fails\n" +
          "    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '" + packageName.replace("'", "\\'" ) + "'])\n", globals);
      
      // Get the captured output
      PyObject stdout = python.getBuiltins().get("eval").call("sys.stdout.getvalue()", globals);
      PyObject stderr = python.getBuiltins().get("eval").call("sys.stderr.getvalue()", globals);
      String output = stdout != null ? stdout.toString() : "";
      String error = stderr != null ? stderr.toString() : "";
      
      // Restore stdout and stderr
      python.getBuiltins().get("exec").call("sys.stdout = _stdout\nsys.stderr = _stderr", globals);
      
      // Try to import the package to verify it was installed
      boolean installed = false;
      try {
        python.getBuiltins().get("exec").call("import " + packageName.split("[<>=!~]")[0].trim(), globals);
        installed = true;
      } catch (PyException e) {
        // Package might be installed but not importable by the same name (e.g., python-dateutil vs dateutil)
        // So we don't fail here, just note it
        output += "\nNote: Package installed but could not be imported directly. It may have a different import name.";
      }
      
      Map<String, Object> successResult = new HashMap<>();
      successResult.put("success", true);
      successResult.put("output", output);
      successResult.put("error", error);
      successResult.put("installed", installed);
      result.success(successResult);
    } catch (Exception e) {
      Map<String, Object> errorResult = new HashMap<>();
      errorResult.put("success", false);
      errorResult.put("error", e.getMessage());
      result.success(errorResult);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
