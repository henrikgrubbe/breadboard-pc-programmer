export function debounce(fn: any, delay: number) {
    let timeout: number | undefined;

    return (...args: any) => {
        if (timeout) {
            clearTimeout(timeout);
        }

        timeout = setTimeout(() => {
            fn(...args)
        }, delay)
    }
}
