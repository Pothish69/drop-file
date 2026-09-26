async function uploadFile() {

    // Get file input
    const input =
        document.getElementById('fileInput');

    // Get status element
    const status =
        document.getElementById('status');

    // Get upload button
    const button =
        document.getElementById('uploadButton');


    // Check if user selected a file

    if (input.files.length === 0) {

        status.innerText =
            'Please select a file first.';

        return;
    }


    // Get selected file

    const file =
        input.files[0];


    // Show uploading message

    status.innerText =
        'Uploading ' + file.name + '...';


    // Disable button

    button.disabled = true;


    try {

        // Send file to Flutter server

        const response =
            await fetch('/upload', {

                method: 'POST',

                headers: {

                    'X-File-Name':
                        file.name

                },

                body: file

            });


        // Get server response

        const result =
            await response.text();


        // Check result

        if (response.ok) {

            status.innerText =
                '✅ ' + result;

            // Clear selected file

            input.value = '';

        } else {

            status.innerText =
                '❌ ' + result;

        }


    } catch (error) {

        console.error(error);

        status.innerText =
            '❌ Upload error: ' + error;

    }


    // Enable button again

    button.disabled = false;

}