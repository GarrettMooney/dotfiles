# config
for file in $HOME/.{exports,functions,extra,aliases}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
