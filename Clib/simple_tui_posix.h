/*
 * simple_tui_posix.h - terminal calls for TUI_BACKEND_POSIX (macOS and Linux).
 *
 * Input stays in the terminal's byte stream; TUI_INPUT_PARSER turns it into
 * events. Ctrl-C keeps raising SIGINT, as ENABLE_PROCESSED_INPUT does on
 * Windows.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef SIMPLE_TUI_POSIX_H
#define SIMPLE_TUI_POSIX_H

#include <errno.h>
#include <poll.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

/* Save the terminal's settings and switch to raw input. Answers the saved
   record for stp_raw_end, or NULL when stdin is not a terminal. */
static void* stp_raw_begin(void)
{
    struct termios* l_saved = (struct termios*) malloc(sizeof(struct termios));
    struct termios l_raw;
    if (!l_saved) return NULL;
    if (tcgetattr(STDIN_FILENO, l_saved) != 0) {
        free(l_saved);
        return NULL;
    }
    l_raw = *l_saved;
    l_raw.c_iflag &= ~(tcflag_t) (ICRNL | IXON | INLCR | IGNCR);
    l_raw.c_lflag &= ~(tcflag_t) (ICANON | ECHO | IEXTEN);
    l_raw.c_cc[VMIN] = 1;
    l_raw.c_cc[VTIME] = 0;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &l_raw);
    return l_saved;
}

static void stp_raw_end(void* a_saved)
{
    if (a_saved) {
        tcsetattr(STDIN_FILENO, TCSAFLUSH, (struct termios*) a_saved);
        free(a_saved);
    }
}

/* Terminal size into `a_width' and `a_height'; left alone if unknown. */
static void stp_size(int* a_width, int* a_height)
{
    struct winsize l_size;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &l_size) == 0 && l_size.ws_col > 0 && l_size.ws_row > 0) {
        *a_width = (int) l_size.ws_col;
        *a_height = (int) l_size.ws_row;
    }
}

static void stp_write(const char* a_bytes, int a_count)
{
    int l_done = 0;
    ssize_t l_written;
    while (l_done < a_count) {
        l_written = write(STDOUT_FILENO, a_bytes + l_done, (size_t) (a_count - l_done));
        if (l_written > 0) {
            l_done += (int) l_written;
        } else if (l_written == 0 || errno != EINTR) {
            return;
        }
    }
}

/* Is input waiting, within `a_timeout_ms'? */
static int stp_input_ready(int a_timeout_ms)
{
    struct pollfd l_wait;
    int l_result;
    l_wait.fd = STDIN_FILENO;
    l_wait.events = POLLIN;
    l_wait.revents = 0;
    do {
        l_result = poll(&l_wait, 1, a_timeout_ms);
    } while (l_result < 0 && errno == EINTR);
    return l_result > 0 ? 1 : 0;
}

/* Read what is waiting. Bytes read; 0 at end of input. */
static int stp_read(void* a_buffer, int a_capacity)
{
    ssize_t l_read;
    do {
        l_read = read(STDIN_FILENO, a_buffer, (size_t) a_capacity);
    } while (l_read < 0 && errno == EINTR);
    return l_read > 0 ? (int) l_read : 0;
}

#endif /* SIMPLE_TUI_POSIX_H */
