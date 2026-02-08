import os
import random
import struct
import sys
import hashlib # Import hashlib for SHA-256 calculation
import string # Import string for character generation

# --- Constants ---
NUM_MESSAGES = 100
MAX_MESSAGE_LENGTH_CHARS = 512 # Max length for original message in characters
OUTPUT_DIR = r"e:\VSCode\python_sha256" # Use raw string for Windows paths and specify subfolder
UTF8_TESTCASES_FILE = os.path.join(OUTPUT_DIR, "utf8_testcases.txt") # New input file name
SOC_INPUT_MIF_FILE = os.path.join(OUTPUT_DIR, "soc_input_data.mif") # New MIF file
EXPECTED_HASHES_FILE = os.path.join(OUTPUT_DIR, "expected_sha256_hashes.txt") # File for expected hashes

# --- Helper Functions ---

def sha256_padding(message_bytes):
    """
    Applies SHA-256 padding to a byte message.

    Args:
        message_bytes: The original message as bytes.

    Returns:
        A tuple containing:
        - padded_data: The message with SHA-256 padding applied (bytes).
        - padded_length_bytes: The length of the padded_data in bytes (int).
    """
    original_length_bytes = len(message_bytes)
    original_length_bits = original_length_bytes * 8

    # 1. Append the bit '1' (which is byte 0x80)
    padded_message = message_bytes + b'\x80'

    # 2. Append '0' bits (0x00 bytes) until message length in bytes is congruent to 56 (mod 64)
    current_length_bytes = len(padded_message)
    num_zero_bytes = (56 - (current_length_bytes % 64)) % 64
    padded_message += b'\x00' * num_zero_bytes

    # 3. Append original length in bits as a 64-bit big-endian integer
    padded_message += struct.pack('>Q', original_length_bits)

    padded_length_bytes = len(padded_message)

    # Sanity check: padded length must be a multiple of 64 bytes (512 bits)
    if padded_length_bytes % 64 != 0:
        raise ValueError(f"Padding error: Final length {padded_length_bytes} is not a multiple of 64.")

    return padded_message, padded_length_bytes

# --- Main Script Logic ---

def generate_utf8_testcases(filename, num_messages, max_length_chars):
    """
    Generates random UTF-8 text messages and saves them to a text file.
    Each line in the output file contains one UTF-8 message.
    Uses printable ASCII characters for simplicity.
    """
    print(f"Generating {num_messages} random UTF-8 messages (max length {max_length_chars} chars)...")
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    # Define the character pool (e.g., printable ASCII)
    # You could expand this to include other Unicode characters if needed
    char_pool = string.printable
    try:
        # Ensure file is opened with utf-8 encoding for writing
        with open(filename, 'w', encoding='utf-8') as f:
            for i in range(num_messages):
                msg_len = random.randint(0, max_length_chars)
                # Generate random string from the character pool
                random_msg_str = ''.join(random.choice(char_pool) for _ in range(msg_len))
                # Write the UTF-8 string directly, add newline
                f.write(random_msg_str + '\n')
        print(f"Successfully generated and saved UTF-8 test cases to: {filename}")
    except IOError as e:
        print(f"Error writing to {filename}: {e}")
        sys.exit(1)

def process_and_format_data(input_filename):
    """
    Reads UTF-8 encoded messages line by line, encodes them to bytes,
    calculates SHA-256 hash of the original message bytes, applies SHA-256 padding,
    formats data for MIF (length + padded data as 32-bit hex words),
    and returns the list of hex words and calculated SHA-256 hashes (hex digests).
    """
    print(f"Processing messages from {input_filename} for MIF generation...")
    mif_words = [] # List to store 32-bit hex words for MIF
    expected_hashes = [] # List to store expected SHA-256 hashes

    os.makedirs(os.path.dirname(input_filename), exist_ok=True) # Ensure dir exists

    try:
        # Ensure file is opened with utf-8 encoding for reading
        with open(input_filename, 'r', encoding='utf-8') as infile:
            for line_num, line in enumerate(infile):
                # Read the line as a UTF-8 string, remove trailing newline
                utf8_string = line.rstrip('\n')
                # Encode the UTF-8 string to bytes for processing
                original_message = utf8_string.encode('utf-8')

                # Calculate expected hash on the original message bytes
                sha256_hash = hashlib.sha256(original_message).hexdigest()
                expected_hashes.append(sha256_hash)

                # Pad the message bytes
                padded_data, padded_length_bytes = sha256_padding(original_message)

                # Add Padded_Length as the first word (Big Endian hex string)
                length_bytes = struct.pack('>I', padded_length_bytes)
                mif_words.append(length_bytes.hex()) # e.g., '00000080' for 128 bytes

                # Add Padded_Data in 32-bit (4-byte) chunks as hex strings
                if len(padded_data) % 4 != 0:
                     # This shouldn't happen if padding is correct (multiple of 64 bytes)
                     raise ValueError("Internal error: Padded data length is not a multiple of 4 bytes!")

                for i in range(0, len(padded_data), 4):
                    chunk = padded_data[i:i+4]
                    mif_words.append(chunk.hex()) # Add chunk as hex string 'XXXXXXXX'

    except FileNotFoundError:
        print(f"Error: Input file not found: {input_filename}")
        sys.exit(1)
    except IOError as e:
        print(f"Error reading from {input_filename}: {e}")
        sys.exit(1)
    except UnicodeDecodeError as e:
        print(f"Error decoding line {line_num + 1} as UTF-8 in {input_filename}: {e}")
        sys.exit(1)


    # Add the final end marker (4 bytes of zero -> 32-bit word 0x00000000)
    mif_words.append("00000000")

    print(f"Finished processing messages. Total MIF words generated: {len(mif_words)}")
    return mif_words, expected_hashes

def write_mif_file(filename, words):
    """
    Writes the list of 32-bit hex words to a .mif file.
    """
    print(f"Writing MIF data to {filename}...")
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    depth = len(words)
    width = 32

    try:
        with open(filename, 'w', encoding='utf-8') as f:
            # Write MIF header
            f.write(f"WIDTH={width};\n")
            f.write(f"DEPTH={depth};\n")
            f.write("ADDRESS_RADIX=HEX;\n")
            f.write("DATA_RADIX=HEX;\n\n")
            f.write("CONTENT BEGIN\n")

            # Write data words with addresses
            for i, word in enumerate(words):
                # Format address with sufficient width (e.g., 8 hex digits if depth is large)
                # Adjust the address format width if needed based on expected depth
                addr_hex = f"{i:X}"
                f.write(f"\t{addr_hex} : {word};\n")

            f.write("END;\n")
        print(f"Successfully created MIF file: {filename}")
    except IOError as e:
        print(f"Error writing to {filename}: {e}")
        sys.exit(1)

def write_expected_output(filename, hashes):
    """
    Writes the list of expected SHA-256 hashes (hex strings) to a file,
    one hash per line.
    """
    print(f"Writing expected SHA-256 hashes to {filename}...")
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for sha_hash in hashes:
                f.write(sha_hash + '\n')
        print(f"Successfully saved expected hashes to: {filename}")
    except IOError as e:
        print(f"Error writing to {filename}: {e}")
        sys.exit(1)

# --- Execution ---
if __name__ == "__main__":
    print("--- Starting Data Generation and Processing ---")

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 1. Generate random UTF-8 test cases
    generate_utf8_testcases(UTF8_TESTCASES_FILE, NUM_MESSAGES, MAX_MESSAGE_LENGTH_CHARS)

    print("\n---")

    # 2. Process messages, generate MIF words and expected hashes
    mif_data_words, expected_sha256_results = process_and_format_data(UTF8_TESTCASES_FILE)

    print("\n---")

    # 3. Write the MIF data words to the .mif file
    write_mif_file(SOC_INPUT_MIF_FILE, mif_data_words)

    print("\n---")

    # 4. Write the expected SHA-256 hashes to a text file
    write_expected_output(EXPECTED_HASHES_FILE, expected_sha256_results)

    print("\n--- Script Finished ---")
