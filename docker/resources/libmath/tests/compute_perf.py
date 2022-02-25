import sys


def parse_line(line):
    function, cycles = line.strip().split(' ')
    return function, int(cycles)


def load_file(filename):
    with open(filename) as fi:
        return dict([parse_line(line) for line in fi])


def compute_slowdown(reference, targets):
    for function, cycles in reference.items():
        print(f'{function:10}', end=' ')
        for target in targets:
            if function in target:
                slowdown = target[function]/cycles
            else:
                slowdown = 0
            print(f' {slowdown:.2f} ', end=' ')
        print()


if '__main__' == __name__:
    reference_filename = sys.argv[1]
    target_filenames = sys.argv[2:]

    reference = load_file(reference_filename)
    targets = [load_file(target_filename)
               for target_filename in target_filenames]

    print(f"Function {' '.join(target_filenames)}")
    compute_slowdown(reference, targets)
