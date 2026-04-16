import os
import sys

def generate_context(output_file="CONTEXT.txt"):
    # Folders to skip
    IGNORE_DIRS = {
        ".git", "node_modules", "__pycache__", ".next", ".gocache", 
        ".gomodcache", "scratch", "artifacts", "vault", ".vscode"
    }
    
    # File extensions to include
    INCLUDE_EXTS = {".go", ".py", ".ts", ".tsx", ".md", ".json", ".yml", ".yaml", ".sh"}
    
    # Specific files to ignore
    IGNORE_FILES = {
        "package-lock.json", "go.sum", "tsconfig.tsbuildinfo", 
        output_file, "CONTEXT.txt"
    }
    
    buf = []
    buf.append("=================================================================")
    buf.append("                    REKALL CODEBASE CONTEXT")
    buf.append("=================================================================\n")
    
    buf.append("--- DIRECTORY STRUCTURE ---\n")
    
    for root, dirs, files in os.walk("."):
        # Filter directories in-place
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        level = root.replace(".", "").count(os.sep)
        indent = " " * 4 * (level)
        buf.append(f"{indent}{os.path.basename(root)}/")
        subindent = " " * 4 * (level + 1)
        for f in files:
            buf.append(f"{subindent}{f}")
            
    buf.append("\n\n=================================================================")
    buf.append("                      FILE CONTENTS")
    buf.append("=================================================================\n")
    
    for root, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        for file in files:
            if file in IGNORE_FILES:
                continue
            
            ext = os.path.splitext(file)[1]
            if ext not in INCLUDE_EXTS and not file.startswith(".env"):
                continue
                
            filepath = os.path.join(root, file)
            buf.append(f"--- FILE: {filepath} ---\n")
            
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                    if len(content) > 20000:
                        content = content[:20000] + "\n\n... [TRUNCATED - FILE TOO LARGE] ..."
                    buf.append(content)
            except Exception as e:
                buf.append(f"Error reading file: {e}")
                
            buf.append("\n\n" + "="*80 + "\n\n")
            
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(buf))
        
    size_mb = os.path.getsize(output_file) / (1024 * 1024)
    print(f"✅ Generated {output_file} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    generate_context()
