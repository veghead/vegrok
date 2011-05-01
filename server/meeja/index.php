<?php
// vim:ts=4
if (isset($_REQUEST['type'])) {
	if ($_REQUEST['type']=='audio') {
        // not needed any more
	    echo '<','?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
	} else {
		echo '<','?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
		echo '<categories>';
		for($i = 0; $i < 36; $i++) {
			$j = (($i < 10) ? "$i" : chr($i + 55));
			echo '<category title="',$j,'" description="',$j,'" ';
			echo 'sd_img="file://pkg:/images/video.jpg" ';
			echo 'hd_img="file://pkg:/images/video.jpg">';
	                echo "\n\t",'<categoryLeaf title="',$j,'" description="" feed="';
			echo 'http://',$_SERVER['SERVER_NAME'].$_SERVER['PHP_SELF'],'?az=',$j,'&amp;t=mp4"/>';
	        	echo "</category>\n";
		}
		echo "</categories>\n";
	}
} else {
	$dsn = 'mysql:dbname=meeja;host=127.0.0.1';
	$user = 'meeja';
	$password = 'candy';
	
	try {
	    $dbh = new PDO($dsn, $user, $password);
	} catch (PDOException $e) {
	    echo 'Connection failed: ' . $e->getMessage();
	}
	
	$first = isset($_REQUEST['az']) ? $_REQUEST['az'] : 'a';
	$restrict = isset($_REQUEST['t']) ? $_REQUEST['t'] : '';
	$sql = "select * from meeja where nicetitle like ? ";
	$params = array($first.'%');
	if ($restrict) {
		$sql .= " and format=?";
		array_push($params,$restrict);
	}
	$sql .= " order by nicetitle ";
	$sth = $dbh->prepare($sql);
	$res = $sth->execute($params);
	header("Content-type: text/xml; charset=UTF-8");
	if ($res) {
		$totalnum = $sth->rowCount();
	echo '<','?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
	?>

	<feed>
	        <resultLength><?php echo $totalnum ?></resultLength>
	        <endIndex><?php echo $totalnum ?></endIndex>
	<?php
		while(($row = $sth->fetch())) {
			$id = $row['id'];
			$title = htmlspecialchars($row['nicetitle']);
			$format = $row['format'];
			$path = preg_replace('/.var.www.meeja./','',$row['path']);
			$url = "http://".$_SERVER['SERVER_NAME']."/meeja/".htmlspecialchars($path);
			$url = preg_replace('/ /','%20',$url);
			$out .= "
	        <item>
	                <title>$title</title>
	                <contentId>$id</contentId>
	                <contentType></contentType>
	                <contentQuality>SD</contentQuality>
	                <streamFormat>$format</streamFormat>
	                <media>
	                        <streamQuality>SD</streamQuality>
	                        <streamBitrate>0</streamBitrate>
	                        <streamUrl>$url</streamUrl>
	                </media>
	                <synopsis></synopsis>
	                <genres>TV</genres>
	        </item>";
		}
	}
	echo "$out</feed>\n";
}
?>
