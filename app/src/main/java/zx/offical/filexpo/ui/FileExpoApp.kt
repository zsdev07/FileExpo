package zx.offical.filexpo.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import zx.offical.filexpo.viewmodel.FileViewModel
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FileExpoApp(viewModel: FileViewModel = viewModel()) {
    val files by viewModel.files.collectAsState()
    val path by viewModel.currentPath.collectAsState()
    val isDark by viewModel.isDarkMode.collectAsState()

    MaterialTheme(colorScheme = if (isDark) darkColorScheme() else lightColorScheme()) {
        Row(modifier = Modifier.fillMaxSize()) {
            
            // Left Pane / Side Rail (Quick Actions)
            NavigationRail(modifier = Modifier.width(80.dp)) {
                NavigationRailItem(
                    icon = { Icon(Icons.Default.ContentCopy, "Copy") },
                    label = { Text("Copy") },
                    selected = false,
                    onClick = { /* Handle selected list */ }
                )
                NavigationRailItem(
                    icon = { Icon(Icons.Default.ContentPaste, "Paste") },
                    label = { Text("Paste") },
                    selected = false,
                    onClick = { viewModel.pasteFiles() }
                )
                NavigationRailItem(
                    icon = { Icon(Icons.Default.FolderZip, "Archive") },
                    label = { Text("Zip") },
                    selected = false,
                    onClick = { /* trigger dialog */ }
                )
            }

            // Right Pane (File Explorer)
            Scaffold(
                topBar = {
                    TopAppBar(
                        title = { Text(path.name) },
                        navigationIcon = {
                            IconButton(onClick = { viewModel.navigateUp() }) {
                                Icon(Icons.Default.ArrowBack, "Back")
                            }
                        },
                        actions = {
                            IconButton(onClick = { viewModel.toggleDarkMode() }) {
                                Icon(if(isDark) Icons.Default.LightMode else Icons.Default.DarkMode, "Toggle Theme")
                            }
                        }
                    )
                }
            ) { padding ->
                LazyColumn(contentPadding = padding, modifier = Modifier.fillMaxSize()) {
                    items(files) { file ->
                        ListItem(
                            headlineContent = { Text(file.name ?: "Unknown") },
                            supportingContent = { Text(if (file.isDirectory) "Folder" else "${file.length() / 1024} KB") },
                            leadingContent = {
                                Icon(
                                    imageVector = if (file.isDirectory) Icons.Default.Folder else Icons.Default.InsertDriveFile,
                                    contentDescription = null
                                )
                            },
                            modifier = Modifier.clickable {
                                if (file.isDirectory) {
                                    viewModel.loadDirectory(File(path, file.name!!))
                                }
                            }
                        )
                        Divider()
                    }
                }
            }
        }
    }
}