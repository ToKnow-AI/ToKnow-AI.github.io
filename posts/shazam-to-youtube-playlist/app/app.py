"""Gradio Shazam to Youtube App"""

import json
import pandas as pd
from pytube import Search, YouTube
import gradio as gr
from gradio.utils import NamedString

def get_youtube_song(title: str, artist: str) -> YouTube | None:
    search_result = Search(f'{title} by {artist}')
    return search_result.results[0] if search_result.results else None

youtube_layer_id = 'youtube-player'
def embed_html(playlist: pd.DataFrame):
    video_ids = [get_youtube_song(*playlist.iloc[i].values).video_id for i in range(len(playlist))]
    video_ids_str: str = json.dumps(video_ids)
    player_html = f"<div id='{youtube_layer_id}' data-video_ids='{video_ids_str}'></div>"
    return gr.HTML(player_html, label="Youtube Player", visible=True)

def upload_file(file: NamedString):
    shazamlibrary_df = pd.read_csv(file, header=1)
    shazamlibrary_df = shazamlibrary_df.drop_duplicates(subset=['TrackKey'])[['Title', 'Artist']]
    playlist = gr.DataFrame(
        shazamlibrary_df, 
        label="Playlist", 
        visible=True,
        column_widths = ['60%', '40%'],
        col_count=(2, 'fixed'),
        row_count=(len(shazamlibrary_df), 'fixed'))
    player = embed_html(shazamlibrary_df)
    return (playlist, player)

body_head = f'''
    <script async src="https://www.youtube.com/iframe_api"></script>
    <style>
        iframe, #{youtube_layer_id} {{
            height:100%; 
            width:100%; 
            min-height: 50vh;
        }}
    </style>
    <script>
        function initPlayer (youtube_player_el, nextVideo) {{
            const youtube_player = window.youtube_player = new YT.Player(youtube_player_el, {{
                height: '100%',
                width: '100%',
                playerVars: {{ autoplay: 1 }},
                events: {{
                    'onReady': function (event) {{
                        event.target.playVideo()
                    }},
                    'onStateChange': function (event) {{
                        if (event.data === YT.PlayerState.ENDED) {{
                            onContinue();
                        }}
                    }},
                    'onError': onContinue,
                    'onAutoplayBlocked': function (event) {{
                        (event.target || youtube_player).playVideo();
                    }}
                }}
            }});

            function onContinue() {{
                nextVideo((value) => {{
                    youtube_player.loadVideoById(value);
                    youtube_player.playVideo();
                }})
            }}

            onContinue();
        }};
        
        const setIntervalId = setInterval(() => {{
            const youtube_player_el = document.getElementById('{youtube_layer_id}');
            if (youtube_player_el) {{
                clearInterval(setIntervalId);
                const video_ids = JSON.parse(youtube_player_el.dataset.video_ids);
                function* generateVideoIds() {{
                    for (const video_id of video_ids) {{
                        yield video_id
                    }}
                }}
                let videoIdGenerator = generateVideoIds();
                function nextVideo(callback) {{
                    let video_id = videoIdGenerator.next().value;
                    if (!video_id) {{
                        videoIdGenerator = generateVideoIds();
                        video_id = videoIdGenerator.next().value;
                    }}
                    callback(video_id);
                }}

                initPlayer(youtube_player_el, nextVideo);
            }}
        }}, 500);
    </script>
'''

with gr.Blocks(head=body_head) as app:
    gr.Markdown("<h1><center>Play your Shazam Playlist from Youtube</center></h1>")
    gr.Markdown("<center>Download the CSV of your playlist from <https://www.shazam.com/myshazam>. </center>")
    gr.Markdown("<center>Upload your Shazam Playlist CSV file.</center>")
    gr.HTML('<hr/>')
    csv = gr.UploadButton(
        label='Upload Shazam Playlist CSV',
        file_count="single",
        file_types = ['.csv'])
    with gr.Row():
        with gr.Column(scale=2):
            player = gr.HTML(label="Youtube Player", visible=False)
        with gr.Column(scale=1):
            playlist = gr.DataFrame(label="Playlist", visible=False)
    csv.upload(upload_file, csv, [playlist, player])

app.launch(debug=True)