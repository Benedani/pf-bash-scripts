# Set array separator to newline only
IFS="
"

printf -v dir '%(%Y-%m-%d)T\n' -1
rm -rf $dir

prev_backups=($(ls -d */ 2>/dev/null))
last_backup=""
if (( ${#prev_backups[@]} > 0 )); then
    last_backup="${prev_backups[$(( ${#prev_backups[@]} - 1 ))]}"
    echo "Previous backup: $last_backup"
fi

mkdir $dir
cd $dir

start_time=$SECONDS

backup_folders=("/run/media/benedani/TrollUSB/" "$HOME/Documents/" "$HOME/Assets/" "$HOME/Music/" "$HOME/Pictures/" "$HOME/Shotcut Projects/" "$HOME/.config/" "$HOME/.local/share/Terraria/")

total_copied_fsize=0
total_hardlinked_fsize=0

function copy_or_hard_link_file() {
    full_path="$1$2"

    if (( ${#prev_backups[@]} > 0 )); then
        other_file="../../$last_backup/$3/$2"
        if cmp --silent $other_file $full_path; then
            if [[ -f "$full_path" ]]; then
                total_hardlinked_fsize=$(( total_hardlinked_fsize + $(stat -c '%s' $full_path) ))
                ln $other_file $2
            fi

            return
        fi
    fi

    if [[ -f "$full_path" ]]; then
        total_copied_fsize=$(( total_copied_fsize + $(stat -c '%s' $full_path) ))
        cp $full_path $2
    fi
}


function copy_or_hard_link() {
    total_copied_fsize=0
    total_hardlinked_fsize=0
    le_start_time=$SECONDS

    from_base_name=$(basename $1)

    mkdir $from_base_name && cd $from_base_name

    echo "$(date -ud "@$(( SECONDS - le_start_time ))" +'%H:%M:%S') - Creating directory structure..."
    directories=($(find $1 -type d))
    for ((_i = 0; _i < ${#directories[@]}; _i++)); do
        mkdir -p "${directories[$_i]:${#1}}" 2>/dev/null
    done

    files=($(find $1 -type f))

    echo "$(date -ud "@$(( SECONDS - le_start_time ))" +'%H:%M:%S') - Backing up files..."
    le_last_time=$SECONDS

    for ((_i = 0; _i < ${#files[@]}; _i++)); do
        copy_or_hard_link_file $1 "${files[$_i]:${#1}}" $from_base_name

        if (( $(( SECONDS - le_last_time )) >= 300 )); then
            echo "$(date -ud "@$(( SECONDS - le_start_time ))" +'%H:%M:%S') - $_i / ${#files[@]} files backed up"
            le_last_time=$(( $le_last_time + 300 ))
        fi
    done

    cd ..
}

for ((i = 0; i < ${#backup_folders[@]}; i++)); do
    folder="${backup_folders[$i]}"
    echo "Backing up $folder..."
    local_start_time=$SECONDS
    copy_or_hard_link "$folder" ./
    local_elapsed=$(( SECONDS - local_start_time ))
    echo "$folder backed up: $(date -ud "@$local_elapsed" +'%H hr %M min %S sec'), copied $(numfmt --to=iec-i --suffix=B --format="%9.2f" $total_copied_fsize), hardlinked $(numfmt --to=iec-i --suffix=B --format="%9.2f" $total_hardlinked_fsize)"
done

elapsed=$(( SECONDS - start_time ))
echo "Backup complete: $(date -ud "@$elapsed" +'%H hr %M min %S sec')"
