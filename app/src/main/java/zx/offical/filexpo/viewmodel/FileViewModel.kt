package zx.offical.filexpo.viewmodel

import android.os.Environment
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import zx.offical.filexpo.utils.ArchiveManager
import java.io.File

enum class SortType { NAME, SIZE, TYPE, DATE }

class FileViewModel : ViewModel() {
    private val root = Environment.getExternalStorageDirectory()
    
    private val _currentPath = MutableStateFlow(root)
    val currentPath: StateFlow<File> = _currentPath

    private val _files = MutableStateFlow<List<DocumentFile>>(emptyList())
    val files: StateFlow<List<DocumentFile>> = _files

    private val _isDarkMode = MutableStateFlow(true)
    val isDarkMode: StateFlow<Boolean> = _isDarkMode

    private var clipboard = mutableListOf<DocumentFile>()
    private var isCutAction = false
    
    private var currentSort = SortType.NAME

    init {
        loadDirectory(root)
    }

    fun loadDirectory(dir: File) {
        viewModelScope.launch(Dispatchers.IO) {
            _currentPath.value = dir
            val docFile = DocumentFile.fromFile(dir)
            val list = docFile.listFiles().toList()
            
            _files.value = when (currentSort) {
                SortType.NAME -> list.sortedBy { it.name?.lowercase() }
                SortType.SIZE -> list.sortedBy { it.length() }
                SortType.TYPE -> list.sortedBy { it.isDirectory }
                SortType.DATE -> list.sortedByDescending { it.lastModified() }
            }
        }
    }

    fun toggleDarkMode() { _isDarkMode.value = !_isDarkMode.value }

    fun navigateUp() {
        _currentPath.value.parentFile?.let { if (it.absolutePath.contains(root.absolutePath)) loadDirectory(it) }
    }

    // --- File Ops ---
    fun copyFiles(selected: List<DocumentFile>) { clipboard = selected.toMutableList(); isCutAction = false }
    fun cutFiles(selected: List<DocumentFile>) { clipboard = selected.toMutableList(); isCutAction = true }
    
    fun pasteFiles() {
        viewModelScope.launch(Dispatchers.IO) {
            clipboard.forEach { doc ->
                // Basic representation using java.io.File for speed/reliability in real app
                val src = File(_currentPath.value.absolutePath, doc.name!!)
                val dest = File(_currentPath.value, doc.name!!)
                src.copyRecursively(dest, true)
                if (isCutAction) src.deleteRecursively()
            }
            clipboard.clear()
            loadDirectory(_currentPath.value)
        }
    }

    fun compressFiles(files: List<DocumentFile>, outName: String, pass: String?) {
        viewModelScope.launch {
            val dest = File(_currentPath.value, "$outName.zip")
            val srcFiles = files.map { File(_currentPath.value, it.name!!) }
            ArchiveManager.compressToZip(srcFiles, dest, pass)
            loadDirectory(_currentPath.value)
        }
    }
}