import random

def generate_coe_file(filename):
    header = (
        "; This .coe file specifies initialization values for a block memory.\n"
        "; Memory Initialization File (.coe)\n"
        "memory_initialization_radix=2;\n"
        "memory_initialization_vector=\n"
    )

    with open(filename, 'w') as f:
        f.write(header)

        for i in range(128): #depth
            random_value = ''.join(random.choice('01') for _ in range(512)) #width
            if i < 127:
                f.write(random_value + ",\n")
            else:
                f.write(random_value + ";")

for i in range(3): #number of files
    filename = f"memory_{i+1}.coe"
    generate_coe_file(filename)
    print(f"Generated {filename}")

print("All .coe files have been generated.")
