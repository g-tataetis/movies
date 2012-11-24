#!/usr/bin/perl

use warnings;
use diagnostics;

$movies_folder = "/media/arc/movies";

@movies_all = `ls $movies_folder`;
foreach $movie_folder (@movies_all){
	print "$movie_folder\n";
	chomp($movie_folder);
	print "Name to search for: "; chomp($name_to_search_for = <STDIN>);
	$name_to_search_for =~ s/ /+/g;
	system("wget -q http://www.imdb.com/find?q=$name_to_search_for\\\&s=tt -O index.html");
	open IMDBSEARCHRESULT, "<index.html";
	unlink("index.html");
	@imdb_search_result = <IMDBSEARCHRESULT>;
	close(IMDBSEARCHRESULT);
	foreach $line_of_search_result (@imdb_search_result){
		if($line_of_search_result =~ /.*<p><b>Popular Titles<\/b>.*/){
			$popular_titles = $line_of_search_result;
		}
		elsif($line_of_search_result =~ /.*<p><b>Titles \(Partial Matches\)<\/b>.*/){
			$partial_titles = $line_of_search_result;
		}
	}
	print "Titles:\n";
	@popular_titles = split("<br>", $popular_titles);
	$q = 0;
	@title_imdb_code = ();
	@title_info = ();
	$current_popular_title_info = "";
	foreach $popular_title (@popular_titles){
		if($popular_title =~ /.*<a href="\/title\/tt(\d+)\/"\s+onclick=".*">(.*)<\/a>\s+.*/){
			$current_popular_title_info = $2;
			chomp($current_popular_title_info);
			$title_imdb_code[$q] = $1;
			$title_info[$q] = $current_popular_title_info;
			print "\t$q: " .  $title_imdb_code[$q] . "\t" . $title_info[$q] . "\n";
			$q++;
		}
	}
	@partial_titles = split("<br>", $partial_titles);
	$current_partial_title_info = "";
	foreach $partial_title (@partial_titles){
		if($partial_title =~ /.*<a href="\/title\/tt(\d+)\/"\s+onclick=".*">(.*)<\/a>\s+.*/){
			$current_partial_title_info = $2;
			chomp($current_partial_title_info);
			$title_imdb_code[$q] = $1;
			$title_info[$q] = $current_partial_title_info;
			print "\t$q: " .  $title_imdb_code[$q] . "\t" . $title_info[$q] . "\n";
			$q++;
		}
	}
	do {
		print "command:/>"; chomp($user_command = <STDIN>);
		if($user_command =~ /^visit\s+(.*)/){
			$to_visit_links = $1;
			chomp($to_visit_links);
			@to_visit_links = split(" ", $to_visit_links);
			foreach $to_visit_link (@to_visit_links){
				chomp($to_visit_link);
				$full_to_visit_link = "http://www.imdb.com/title/tt" . $title_imdb_code[$to_visit_link];
				system("firefox $full_to_visit_link &");
			}
		}
		elsif($user_command =~ /^add\s+(\d+).*/){
			$current_imdb_code = $title_imdb_code[$1];
			$current_title_info = $title_info[$1];
			$full_movie_directory = $movies_folder . "/" . $movie_folder;
			$renamed_movie_directory = $movies_folder . "/" . $title_imdb_code[$1];
#			print "mv -vf \"$full_movie_directory\" \"$renamed_movie_directory\"";
			$full_to_visit_link = "http://www.imdb.com/title/tt" . $title_imdb_code[$1];
			system("wget -q $full_to_visit_link -O movie.html");
			open IMDBMOVIEPAGE, "<movie.html";
			@imdb_movie_page = <IMDBMOVIEPAGE>;
			unlink("movie.html");
			close(IMDBMOVIEPAGE);
			$current_movie_ratings = "";
			$current_movie_users = "";
			$current_movie_genres = "";
			foreach $line_of_imdb_movie_page (@imdb_movie_page){
				if($line_of_imdb_movie_page =~ /.*Ratings: <strong><span itemprop="ratingValue">(\S+)<\/span>.*/){
					$current_movie_ratings = $1;
					print "\t\tRating: $current_movie_ratings\n";
				}
				elsif($line_of_imdb_movie_page =~ /.*><span itemprop="ratingCount">(\S+)<\/span> users<\/a>.*/){
					$current_movie_users = $1;
					$current_movie_users =~ s/,//g;
					print "\t\tUsers:  $current_movie_users\n";
				}
				elsif($line_of_imdb_movie_page =~ /.*href="\/genre\/.*"\s+>.*<\/a>.*/){
					@raw_genres_of_current_movie = split("</span>", $line_of_imdb_movie_page);
					foreach $raw_genre (@raw_genres_of_current_movie){
						if($raw_genre =~ /.*href="\/genre\/.*"\s+>(.+)<\/a>.*/){
							$current_movie_genres .= $1 . ", ";
						}
					}
				}
			}
			chomp($current_movie_genres);
			chop($current_movie_genres);
			$current_movie_score = $current_movie_ratings*$current_movie_users;
			print "\t\tMovie score: $current_movie_score\n";
			print "\t\tMovie genres: $current_movie_genres\n";
			open DATABASE, ">>database";
			print DATABASE "$current_imdb_code\t\t$current_title_info\t$current_movie_score\t\t$current_movie_ratings\t$current_movie_users\t$current_movie_genres\n";
		}
		elsif($user_command =~ /^exit/){
			exit;
		}
	} while($user_command !~ /^next/);
}