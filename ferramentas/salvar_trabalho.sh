#!/bin/bash
# Copia o estado de trabalho (progresso e notas, sem texto dos livros) para o repo.
mkdir -p /home/claude/jogo-livros/livros/_trabalho/notas
cp /home/claude/textos/PROGRESSO.md /home/claude/jogo-livros/livros/_trabalho/ 2>/dev/null || true
cp /home/claude/textos/notas/*.md /home/claude/jogo-livros/livros/_trabalho/notas/ 2>/dev/null || true
