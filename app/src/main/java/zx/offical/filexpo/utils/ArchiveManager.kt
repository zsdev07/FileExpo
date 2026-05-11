package zx.offical.filexpo.utils

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import net.lingala.zip4j.ZipFile
import net.lingala.zip4j.model.ZipParameters
import net.lingala.zip4j.model.enums.AesKeyStrength
import net.lingala.zip4j.model.enums.EncryptionMethod
import com.github.junrar.Junrar
import java.io.File

object ArchiveManager {
    
    // Fast IO thread offloading to prevent ANR
    suspend fun compressToZip(files: List<File>, dest: File, password: String? = null) = withContext(Dispatchers.IO) {
        val zipFile = if (password.isNullOrEmpty()) ZipFile(dest) else ZipFile(dest, password.toCharArray())
        val params = ZipParameters().apply {
            if (!password.isNullOrEmpty()) {
                isEncryptFiles = true
                encryptionMethod = EncryptionMethod.AES
                aesKeyStrength = AesKeyStrength.KEY_STRENGTH_256
            }
        }
        
        for (f in files) {
            if (f.isDirectory) zipFile.addFolder(f, params) else zipFile.addFile(f, params)
        }
    }

    suspend fun extractArchive(archiveFile: File, destFolder: File, password: String? = null) = withContext(Dispatchers.IO) {
        val name = archiveFile.name.lowercase()
        when {
            name.endsWith(".zip") -> {
                val zip = if (password.isNullOrEmpty()) ZipFile(archiveFile) else ZipFile(archiveFile, password.toCharArray())
                zip.extractAll(destFolder.absolutePath)
            }
            name.endsWith(".rar") -> {
                // Junrar natively supports multi-part split (.part1.rar) detection
                Junrar.extract(archiveFile, destFolder)
            }
            // Add Apache Commons compress logic for 7z/tar here...
        }
    }
}