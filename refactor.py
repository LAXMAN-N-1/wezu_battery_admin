import os
import glob

def find_matching_paren(text, start_index):
    count = 0
    for i in range(start_index, len(text)):
        if text[i] == '(':
            count += 1
        elif text[i] == ')':
            count -= 1
            if count == 0:
                return i
    return -1

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False

    # 1. Wrap DataTable with SingleChildScrollView
    search_str = 'child: DataTable('
    idx = 0
    while True:
        idx = content.find(search_str, idx)
        if idx == -1:
            break
        # Make sure it's not already wrapped
        if 'SingleChildScrollView(scrollDirection: Axis.horizontal' in content[max(0, idx-100):idx]:
            idx += len(search_str)
            continue
            
        # Find the end of DataTable(...)
        start_paren = idx + len(search_str) - 1
        end_paren = find_matching_paren(content, start_paren)
        
        if end_paren != -1:
            # Insert wrapper
            content = content[:end_paren+1] + ')' + content[end_paren+1:]
            content = content[:idx] + 'child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(' + content[start_paren+1:]
            modified = True
        
        idx += len('child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(')

    # 2. Convert high-level Row to Wrap
    # We look for Row(children: [ ... Spacer() ... ])
    # Because there are many Rows, we use a heuristic: Any Row that contains 'Spacer()' directly inside its children or is followed by elements
    
    # Actually, a simpler regex/heuristic for Header Rows:
    # Row( children: [ ... Text( ... Spacer() ... ] )
    idx = 0
    while True:
        idx = content.find('Row(', idx)
        if idx == -1:
            break
            
        start_paren = idx + 3
        end_paren = find_matching_paren(content, start_paren)
        
        if end_paren != -1:
            row_content = content[start_paren:end_paren+1]
            if 'const Spacer()' in row_content or 'Spacer()' in row_content:
                # Replace Spacer
                new_row_content = row_content.replace('const Spacer(),', '')
                new_row_content = new_row_content.replace('Spacer(),', '')
                # Change Row to Wrap
                replacement = 'Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,' + new_row_content[1:]
                content = content[:idx] + replacement + content[end_paren+1:]
                modified = True
                
        idx += 1

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Refactored {filepath}")

if __name__ == '__main__':
    files = glob.glob('lib/features/**/view/*.dart', recursive=True)
    for f in files:
        process_file(f)
    print("Done")
