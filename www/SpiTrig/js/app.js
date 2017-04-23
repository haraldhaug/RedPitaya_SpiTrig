(function(APP, $, undefined) {
    
    // App configuration
    APP.config = {};
    APP.config.app_id = 'SpiTrig';
    APP.config.app_url = '/bazaar?start=' + APP.config.app_id + '?' + location.search.substr(1);
    APP.config.socket_url = 'ws://' + window.location.hostname + ':9002';

    // WebSocket
    APP.ws = null;
    // Signal stack
    APP.signalStack = [];

    //LED state
    //APP.led_state = false;
    //APP.usr_in = "A";
    //APP.spi_rg = 300;
    APP.spi_sim_flag = true;       //SpiSimFlag
    APP.spi_sim_bits = 16;         //SpiSimBits
    APP.spi_sim_mosi = "33AA";     //SpiSimMosi
    APP.spi_sim_period = 600;      //SpiSimPeriod
    APP.spi_tr_mosi_mask = "FFFF"; //SpiTrMosiMask
    APP.spi_tr_mosi = "33AA";      //SpiTrMosi
    APP.spi_tr_miso_flag = true;   //SpiTrMisoFlag
    APP.spi_tr_miso_mask = "FFFF"  //SpiTrMisoMask
    APP.spi_tr_miso = "3001";      //SpiTrMiso    



    // Starts template application on server
    APP.startApp = function() {

        $.get(APP.config.app_url)
            .done(function(dresult) {
                if (dresult.status == 'OK') {
                    APP.connectWebSocket();
                } else if (dresult.status == 'ERROR') {
                    console.log(dresult.reason ? dresult.reason : 'Could not start the application (ERR1)');
                    APP.startApp();
                } else {
                    console.log('Could not start the application (ERR2)');
                    APP.startApp();
                }
            })
            .fail(function() {
                console.log('Could not start the application (ERR3)');
                APP.startApp();
            });
    };




    APP.connectWebSocket = function() {

        //Create WebSocket
        if (window.WebSocket) {
            APP.ws = new WebSocket(APP.config.socket_url);
            APP.ws.binaryType = "arraybuffer";
        } else if (window.MozWebSocket) {
            APP.ws = new MozWebSocket(APP.config.socket_url);
            APP.ws.binaryType = "arraybuffer";
        } else {
            console.log('Browser does not support WebSocket');
        }


        // Define WebSocket event listeners
        if (APP.ws) {

            APP.ws.onopen = function() {
                $('#status_message').text("SPI trigger connected!");
                console.log('Socket opened');   
            };

            APP.ws.onclose = function() {
                console.log('Socket closed');
            };

            APP.ws.onerror = function(ev) {
                $('#status_message').text("Connection error");
                console.log('Websocket error: ', ev);         
            };

            APP.ws.onmessage = function(ev) {
                console.log('Message recieved');
            };
        }
    };
    


}(window.APP = window.APP || {}, jQuery));




// Page onload event handler
$(function() {
     
    $('#SpiSimFlag').on("change", function() {
        APP.spi_sim_flag = $('#SpiSimFlag').is(":checked");
        if (APP.spi_sim_flag ){
            $('#SpiSimTable').show();
        }
        else{
            $('#SpiSimTable').hide();
        } 
        var local = {};
        local['SPI_SIM_FLAG'] = { value: APP.spi_sim_flag };
        APP.ws.send(JSON.stringify({ parameters: local }));
    });
    $("#SpiSimPeriod").on("change input", function() {
        APP.spi_sim_period = $('#SpiSimPeriod').val();
        $('#SpiSimPeriodTx').val((APP.spi_sim_period).toString(16));
        var local = {};
        local['SPI_SIM_PERIOD'] = { value: APP.spi_sim_period };
        APP.ws.send(JSON.stringify({ parameters: local }));
	});
    $('#SpiTrMisoFlag').on("change", function() {
        APP.spi_tr_miso_flag = $('#SpiTrMisoFlag').is(":checked");
        if ( APP.spi_tr_miso_flag ){
            $('#SpiTrMisoTable').show();
        }
        else{
            $('#SpiTrMisoTable').hide();
        } 
        var local = {};
        local['SPI_TR_MISO_FLAG'] = { value: APP.spi_tr_miso_flag };
        APP.ws.send(JSON.stringify({ parameters: local }));
    });
    $("#SpiSimBits").on("change", function() {
        APP.spi_sim_bits = $('#SpiSimBits').val();
        var local = {};
        local['SPI_SIM_BITS'] = { value: APP.spi_sim_bits };
        APP.ws.send(JSON.stringify({ parameters: local }));
	});
    $("#SpiTrMosiMask").on("change", function() {
        APP.spi_tr_mosi_mask = $('#SpiTrMosiMask').val();
        var local = {};
        local['SPI_TR_MOSI_MASK'] = { value: APP.spi_tr_mosi_mask };
        APP.ws.send(JSON.stringify({ parameters: local }));
	});
    $("#SpiTrMosi").on("change", function() {
        APP.spi_tr_mosi = $('#SpiTrMosi').val();
        var local = {};
        local['SPI_TR_MOSI'] = { value: APP.spi_tr_mosi };
        APP.ws.send(JSON.stringify({ parameters: local }));
	});
    $("#SpiTrMisoMask").on("change", function() {
        APP.spi_tr_miso_mask = $('#SpiTrMisoMask').val();
        var local = {};
        local['SPI_TR_MISO_MASK'] = { value: APP.spi_tr_miso_mask };
        APP.ws.send(JSON.stringify({ parameters: local }));
	});
    $("#SpiTrMiso").on("change", function() {
        APP.spi_tr_miso = $('#SpiTrMiso').val();
        var local = {};
        local['SPI_TR_MISO'] = { value: APP.spi_tr_miso };
        APP.ws.send(JSON.stringify({ parameters: local }));
	});

    
    // Start application
    APP.startApp();
});
