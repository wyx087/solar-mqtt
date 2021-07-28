<html>
<head>

<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="0" />

<meta content="text/html;charset=utf-8" http-equiv="Content-Type">
<meta content="utf-8" http-equiv="encoding">
<script type="text/javascript" src="dygraph-combined.js"></script>

<title>Solar generation and usage graph </title>
</head>
<body>
    <meta name="viewport" content="width=800px">
    <br>
    
    
    <select id='dropdownfiles' onchange="drawgraph()">
    <option selected="selected" value="solar.csv">solar.csv</option>
    <?php
    $files = array_map("htmlspecialchars", scandir("log"));
    $last_files = array_reverse($files);
    foreach ($last_files as $file) {
        if ($i > 31) {                // Set a limit of how far back to go 
            break;
        } elseif ($file[0] == ".") {  // To prevent . and .. showing up 
            null;
        } elseif ($file == "solar.csv"){ // Already adding this entry manually  
            null;
        } elseif ($file == "solar_short.csv"){ // Solarshort is for index page and pi page only 
            null;
        }else {
            echo "<option value='$file'>$file</option>";
            $i = $i + 1;
        }
    }
    ?>
    </select>
    <br><br>
    
    <div id="mygraph"
        style="width:800px; height:600px;"></div>
    
    <p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <input type=checkbox id="0" checked onClick="change(this)">
      <label for="0"> <font color="#000000">Usage</font></label>&nbsp;
      <input type=checkbox id="1" checked onClick="change(this)">
      <label for="1"> <font color="#00E000">Generating</font></label>&nbsp;
      <input type=checkbox id="2" checked onClick="change(this)">
      <label for="2"> <font color="#FF0000">Exporting</font></label>&nbsp;
    </p>
    <p>
      <input type="button" value="Unzoom" onclick="unzoomGraph()">&nbsp;
      <input type="button" value="Last 8 hours" onclick="selectLasthours(8)">&nbsp;
      <input type="button" value="Last 4 hours" onclick="selectLasthours(4)">&nbsp;
      <input type="button" value="Last 2 hours" onclick="selectLasthours(2)">&nbsp;
      <input type="button" value="Last hour" onclick="selectLasthours(1)">&nbsp;
    </p>


    
    <script type="text/javascript">
        // On page load, run: 
        window.onload = function(){
            setTimeout(function() { drawgraph(); }, 10);
            setTimeout(function() { unzoomGraph(); }, 500);
        };
        
        // Drawing the graph 
        function drawgraph() {
            var csvfile = 'log/' + document.getElementById("dropdownfiles").value;
            g = new Dygraph(
            document.getElementById("mygraph"),
            csvfile, 
                {
                    labels: [ "Time", "Usage", "Generating", "Exporting" ],
                    colors: ['#000000', '#00E000', '#FF0000'],
                    rollPeriod: 20, 
                    showRoller: true,
                    series: {
                       Generating: { fillGraph: true }
                    }
                }
            );
        };
        
        // For Data selector 
        function setStatus() {
        document.getElementById("visibility").innerHTML =
          g.visibility().toString();
        }
        function change(el) {
        g.setVisibility(parseInt(el.id), el.checked);
        setStatus();
        }
        
        // For zoom buttons 
        function unzoomGraph() {
        g.updateOptions({
          dateWindow: null,
          valueRange: null,
          rollPeriod: 1
        });
        }
        function selectLasthours(hours) {
        var range = g.xAxisRange();
        var maxX = range[1];
        var minX = maxX - hours * 60 * 60 * 1000;
        g.updateOptions({
            dateWindow: [minX, maxX],
            rollPeriod: hours
        });
        }
        
        
    </script>

</body>
</html>

