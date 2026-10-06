package `is`.xyz.mpv

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.AutoCompleteTextView
import android.widget.Button
import android.widget.ListView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.google.android.material.dialog.MaterialAlertDialogBuilder

class CommandLineFragment : Fragment() {
    private lateinit var commandInput: AutoCompleteTextView
    private lateinit var outputList: ListView
    private lateinit var executeButton: Button
    private lateinit var clearButton: Button
    
    private val commandHistory = mutableListOf<String>()
    private val outputLines = mutableListOf<String>()
    private var historyIndex = -1
    
    private val commonCommands = listOf(
        "play", "pause", "stop", "quit",
        "seek", "set", "show-text",
        "volume", "mute", "fullscreen",
        "sub-add", "sub-remove", "sub-select",
        "audio-add", "audio-remove", "audio-select",
        "playlist-next", "playlist-prev",
        "ab-loop", "frame-step", "frame-back-step"
    )

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_command_line, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        commandInput = view.findViewById(R.id.command_input)
        outputList = view.findViewById(R.id.output_list)
        executeButton = view.findViewById(R.id.execute_button)
        clearButton = view.findViewById(R.id.clear_button)
        
        // Setup autocomplete
        val adapter = ArrayAdapter(requireContext(), android.R.layout.simple_dropdown_item_1line, commonCommands)
        commandInput.setAdapter(adapter)
        
        // Setup output list
        val outputAdapter = ArrayAdapter(requireContext(), android.R.layout.simple_list_item_1, outputLines)
        outputList.adapter = outputAdapter
        
        // Execute button
        executeButton.setOnClickListener {
            executeCommand()
        }
        
        // Clear button
        clearButton.setOnClickListener {
            outputLines.clear()
            (outputList.adapter as ArrayAdapter<*>).notifyDataSetChanged()
        }
        
        // Handle keyboard input for history
        commandInput.setOnKeyListener { _, keyCode, event ->
            if (event.action == android.view.KeyEvent.ACTION_DOWN) {
                when (keyCode) {
                    android.view.KeyEvent.KEYCODE_DPAD_UP -> {
                        navigateHistory(-1)
                        true
                    }
                    android.view.KeyEvent.KEYCODE_DPAD_DOWN -> {
                        navigateHistory(1)
                        true
                    }
                    android.view.KeyEvent.KEYCODE_ENTER -> {
                        executeCommand()
                        true
                    }
                    else -> false
                }
            } else false
        }
    }
    
    private fun navigateHistory(direction: Int) {
        if (commandHistory.isEmpty()) return
        
        historyIndex += direction
        if (historyIndex < 0) historyIndex = 0
        if (historyIndex >= commandHistory.size) {
            historyIndex = commandHistory.size
            commandInput.setText("")
        } else {
            commandInput.setText(commandHistory[commandHistory.size - 1 - historyIndex])
            commandInput.setSelection(commandInput.text.length)
        }
    }
    
    private fun executeCommand() {
        val input = commandInput.text.toString().trim()
        if (input.isEmpty()) return
        
        // Add to history
        commandHistory.add(input)
        historyIndex = -1
        
        // Parse command
        val parts = input.split(" ", limit = 2)
        val cmd = parts[0].lowercase()
        val args = if (parts.size > 1) parts[1] else ""
        
        try {
            val result = when (cmd) {
                "play" -> {
                    MPVLib.command(arrayOf("play"))
                    "Playing"
                }
                "pause" -> {
                    MPVLib.command(arrayOf("pause"))
                    "Paused"
                }
                "stop" -> {
                    MPVLib.command(arrayOf("stop"))
                    "Stopped"
                }
                "quit" -> {
                    MPVLib.command(arrayOf("quit"))
                    "Quit requested"
                }
                "seek" -> {
                    MPVLib.command(arrayOf("seek", args.ifEmpty { "10" }))
                    "Seeked"
                }
                "volume" -> {
                    val vol = args.ifEmpty { "100" }
                    MPVLib.setPropertyString("volume", vol)
                    "Volume set to $vol"
                }
                "mute" -> {
                    val current = MPVLib.getPropertyBoolean("mute") ?: false
                    MPVLib.setPropertyBoolean("mute", !current)
                    "Mute: ${!current}"
                }
                "fullscreen" -> {
                    val current = MPVLib.getPropertyBoolean("fullscreen") ?: false
                    MPVLib.setPropertyBoolean("fullscreen", !current)
                    "Fullscreen: ${!current}"
                }
                "set" -> {
                    val setArgs = args.split(" ", limit = 2)
                    if (setArgs.size == 2) {
                        MPVLib.setOptionString(setArgs[0], setArgs[1])
                        "Set ${setArgs[0]} = ${setArgs[1]}"
                    } else {
                        "Usage: set <property> <value>"
                    }
                }
                "get" -> {
                    val value = MPVLib.getPropertyString(args)
                    "$args = $value"
                }
                "show-text" -> {
                    MPVLib.command(arrayOf("show-text", args.ifEmpty { "Hello!" }))
                    "Text displayed"
                }
                "playlist-next" -> {
                    MPVLib.command(arrayOf("playlist-next"))
                    "Next track"
                }
                "playlist-prev" -> {
                    MPVLib.command(arrayOf("playlist-prev"))
                    "Previous track"
                }
                "ab-loop" -> {
                    MPVLib.command(arrayOf("ab-loop"))
                    "A-B loop toggled"
                }
                "frame-step" -> {
                    MPVLib.command(arrayOf("frame-step"))
                    "Frame step forward"
                }
                "frame-back-step" -> {
                    MPVLib.command(arrayOf("frame-back-step"))
                    "Frame step backward"
                }
                "sub-add" -> {
                    if (args.isNotEmpty()) {
                        MPVLib.command(arrayOf("sub-add", args))
                        "Subtitle added: $args"
                    } else {
                        "Usage: sub-add <filename>"
                    }
                }
                "sub-select" -> {
                    MPVLib.command(arrayOf("sub-select"))
                    "Subtitle selection changed"
                }
                "audio-add" -> {
                    if (args.isNotEmpty()) {
                        MPVLib.command(arrayOf("audio-add", args))
                        "Audio track added: $args"
                    } else {
                        "Usage: audio-add <filename>"
                    }
                }
                "audio-select" -> {
                    MPVLib.command(arrayOf("audio-select"))
                    "Audio track selection changed"
                }
                "help" -> {
                    buildString {
                        appendLine("Available commands:")
                        appendLine("  play, pause, stop, quit")
                        appendLine("  seek <seconds>")
                        appendLine("  volume <0-100>")
                        appendLine("  mute")
                        appendLine("  fullscreen")
                        appendLine("  set <property> <value>")
                        appendLine("  get <property>")
                        appendLine("  show-text <message>")
                        appendLine("  playlist-next, playlist-prev")
                        appendLine("  sub-add <file>, sub-select")
                        appendLine("  audio-add <file>, audio-select")
                        appendLine("  ab-loop, frame-step, frame-back-step")
                    }
                }
                else -> "Unknown command: $cmd. Type 'help' for list."
            }
            
            addOutput("> $input")
            addOutput(result)
            
        } catch (e: Exception) {
            addOutput("Error: ${e.message}")
        }
        
        commandInput.text.clear()
    }
    
    private fun addOutput(line: String) {
        outputLines.add(line)
        (outputList.adapter as ArrayAdapter<*>).notifyDataSetChanged()
        outputList.setSelection(outputLines.size - 1)
    }
    
    companion object {
        fun newInstance() = CommandLineFragment()
    }
}