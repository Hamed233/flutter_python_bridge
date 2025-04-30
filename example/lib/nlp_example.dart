import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_python_bridge/flutter_python_bridge.dart';

class NLPExamplePage extends StatefulWidget {
  const NLPExamplePage({Key? key}) : super(key: key);

  @override
  State<NLPExamplePage> createState() => _NLPExamplePageState();
}

class _NLPExamplePageState extends State<NLPExamplePage> {
  final PythonBridge _pythonBridge = PythonBridge();
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String _output = '';
  Map<String, dynamic>? _nlpResults;
  String _selectedTask = 'sentiment';
  bool _showCode = false;

  @override
  void initState() {
    super.initState();
    _textController.text = 'I really enjoyed the movie. The acting was superb and the plot was engaging.';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NLP with Python Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Natural Language Processing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Enter text to analyze',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    const Text('Select NLP Task:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTaskChip('Sentiment Analysis', 'sentiment'),
                        _buildTaskChip('Named Entity Recognition', 'ner'),
                        _buildTaskChip('Text Summarization', 'summarize'),
                        _buildTaskChip('Keyword Extraction', 'keywords'),
                        _buildTaskChip('Language Detection', 'language'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Python code section with toggle
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Python Code:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(_showCode ? Icons.visibility_off : Icons.visibility),
                          label: Text(_showCode ? 'Hide Code' : 'Show Code'),
                          onPressed: () {
                            setState(() {
                              _showCode = !_showCode;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_showCode)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Text(
                            _generatePythonCode(_textController.text, _selectedTask),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _processText,
                      child: Text(_isLoading ? 'Processing...' : 'Analyze Text'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_nlpResults != null) ...[  
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Results',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _buildResultsWidget(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_output.isNotEmpty) ...[  
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Python Output',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(_output),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskChip(String label, String task) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedTask == task,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTask = task;
          });
        }
      },
    );
  }

  Widget _buildResultsWidget() {
    switch (_selectedTask) {
      case 'sentiment':
        return _buildSentimentResults();
      case 'ner':
        return _buildNERResults();
      case 'summarize':
        return _buildSummarizationResults();
      case 'keywords':
        return _buildKeywordResults();
      case 'language':
        return _buildLanguageResults();
      default:
        return const Text('No results available');
    }
  }

  Widget _buildSentimentResults() {
    final sentiment = _nlpResults?['sentiment'];
    final score = _nlpResults?['score'];
    
    if (sentiment == null) {
      return const Text('No sentiment results available');
    }
    
    Color sentimentColor;
    IconData sentimentIcon;
    
    if (sentiment == 'positive') {
      sentimentColor = Colors.green;
      sentimentIcon = Icons.sentiment_satisfied;
    } else if (sentiment == 'negative') {
      sentimentColor = Colors.red;
      sentimentIcon = Icons.sentiment_dissatisfied;
    } else {
      sentimentColor = Colors.amber;
      sentimentIcon = Icons.sentiment_neutral;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(sentimentIcon, color: sentimentColor, size: 32),
            const SizedBox(width: 8),
            Text(
              'Sentiment: ${sentiment.toString().toUpperCase()}',
              style: TextStyle(fontWeight: FontWeight.bold, color: sentimentColor, fontSize: 18),
            ),
          ],
        ),
        if (score != null) ...[  
          const SizedBox(height: 8),
          Text('Confidence Score: ${(score * 100).toStringAsFixed(2)}%'),
        ],
      ],
    );
  }

  Widget _buildNERResults() {
    final entities = _nlpResults?['entities'];
    
    if (entities == null || entities.isEmpty) {
      return const Text('No entities found');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Named Entities:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var entity in entities)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEntityColor(entity['label']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entity['label'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entity['text']),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getEntityColor(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'person':
        return Colors.blue;
      case 'organization':
        return Colors.purple;
      case 'location':
        return Colors.green;
      case 'date':
        return Colors.amber;
      case 'time':
        return Colors.orange;
      case 'money':
        return Colors.green.shade800;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSummarizationResults() {
    final summary = _nlpResults?['summary'];
    
    if (summary == null || summary.isEmpty) {
      return const Text('No summary available');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(summary),
      ],
    );
  }

  Widget _buildKeywordResults() {
    final keywords = _nlpResults?['keywords'];
    
    if (keywords == null || keywords.isEmpty) {
      return const Text('No keywords found');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Keywords:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var keyword in keywords)
              Chip(
                label: Text(keyword['word']),
                avatar: CircleAvatar(
                  backgroundColor: Colors.blue.shade800,
                  child: Text(
                    keyword['score'].toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageResults() {
    final language = _nlpResults?['language'];
    final confidence = _nlpResults?['confidence'];
    
    if (language == null) {
      return const Text('No language detection results available');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Language: $language',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        if (confidence != null) ...[  
          const SizedBox(height: 8),
          Text('Confidence: ${(confidence * 100).toStringAsFixed(2)}%'),
        ],
      ],
    );
  }

  Future<void> _processText() async {
    if (_textController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Processing text...';
      _nlpResults = null;
    });

    try {
      // Generate Python code based on the selected task
      final pythonCode = _generatePythonCode(_textController.text, _selectedTask);
      
      // Run the Python code
      final result = await _pythonBridge.runCode(pythonCode);

      setState(() {
        if (result.success) {
          _output = result.output ?? 'Text processed successfully';
          
          // Try to parse the JSON results
          try {
            final jsonStart = _output.indexOf('{');
            final jsonEnd = _output.lastIndexOf('}') + 1;
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonStr = _output.substring(jsonStart, jsonEnd);
              _nlpResults = json.decode(jsonStr);
            }
          } catch (e) {
            print('Error parsing JSON results: $e');
          }
        } else {
          _output = 'Error: ${result.error ?? "Unknown error"}';
        }
      });
    } catch (e) {
      setState(() {
        _output = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generatePythonCode(String text, String task) {
    switch (task) {
      case 'sentiment':
        return '''
import nltk
import json
from nltk.sentiment import SentimentIntensityAnalyzer

# Download necessary NLTK data (if not already downloaded)
try:
    nltk.data.find('vader_lexicon')
except LookupError:
    nltk.download('vader_lexicon')

# Initialize the sentiment analyzer
sia = SentimentIntensityAnalyzer()

# Analyze the sentiment of the text
text = """${text.replaceAll('"""', '\"\"\"')}"""
sentiment_scores = sia.polarity_scores(text)

# Determine the sentiment
if sentiment_scores['compound'] >= 0.05:
    sentiment = 'positive'
elif sentiment_scores['compound'] <= -0.05:
    sentiment = 'negative'
else:
    sentiment = 'neutral'

# Prepare results
results = {
    'sentiment': sentiment,
    'score': abs(sentiment_scores['compound']),
    'details': {
        'positive': sentiment_scores['pos'],
        'negative': sentiment_scores['neg'],
        'neutral': sentiment_scores['neu'],
        'compound': sentiment_scores['compound']
    }
}

# Print results as JSON
print(json.dumps(results))

# Return results
results
''';
      
      case 'ner':
        return '''
import nltk
import json
import spacy

# Load spaCy model
try:
    nlp = spacy.load('en_core_web_sm')
except OSError:
    print('Downloading spaCy model...')
    import sys
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'spacy', 'download', 'en_core_web_sm'])
    nlp = spacy.load('en_core_web_sm')

# Process the text
text = """${text.replaceAll('"""', '\"\"\"')}"""
doc = nlp(text)

# Extract named entities
entities = []
for ent in doc.ents:
    entities.append({
        'text': ent.text,
        'label': ent.label_,
        'start': ent.start_char,
        'end': ent.end_char
    })

# Prepare results
results = {
    'entities': entities
}

# Print results as JSON
print(json.dumps(results))

# Return results
results
''';
      
      case 'summarize':
        return '''
import nltk
import json
from nltk.corpus import stopwords
from nltk.tokenize import sent_tokenize, word_tokenize
from nltk.probability import FreqDist
from heapq import nlargest

# Download necessary NLTK data (if not already downloaded)
try:
    nltk.data.find('punkt')
    nltk.data.find('stopwords')
except LookupError:
    nltk.download('punkt')
    nltk.download('stopwords')

# Process the text
text = """${text.replaceAll('"""', '\"\"\"')}"""

# Tokenize the text into sentences and words
sentences = sent_tokenize(text)
words = word_tokenize(text.lower())

# Remove stopwords
stop_words = set(stopwords.words('english'))
filtered_words = [word for word in words if word.isalnum() and word not in stop_words]

# Calculate word frequencies
freq = FreqDist(filtered_words)

# Calculate sentence scores based on word frequencies
sentence_scores = {}
for i, sentence in enumerate(sentences):
    for word in word_tokenize(sentence.lower()):
        if word in freq:
            if i in sentence_scores:
                sentence_scores[i] += freq[word]
            else:
                sentence_scores[i] = freq[word]

# Get the top sentences for the summary
summary_sentences = nlargest(min(3, len(sentences)), sentence_scores, key=sentence_scores.get)
summary_sentences.sort()
summary = ' '.join([sentences[i] for i in summary_sentences])

# Prepare results
results = {
    'summary': summary,
    'sentence_count': len(sentences),
    'summary_sentence_count': len(summary_sentences)
}

# Print results as JSON
print(json.dumps(results))

# Return results
results
''';
      
      case 'keywords':
        return '''
import nltk
import json
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.probability import FreqDist
from nltk import pos_tag

# Download necessary NLTK data (if not already downloaded)
try:
    nltk.data.find('punkt')
    nltk.data.find('stopwords')
    nltk.data.find('averaged_perceptron_tagger')
except LookupError:
    nltk.download('punkt')
    nltk.download('stopwords')
    nltk.download('averaged_perceptron_tagger')

# Process the text
text = """${text.replaceAll('"""', '\"\"\"')}"""

# Tokenize the text into words
words = word_tokenize(text.lower())

# Remove stopwords and non-alphanumeric words
stop_words = set(stopwords.words('english'))
filtered_words = [word for word in words if word.isalnum() and word not in stop_words]

# Get part-of-speech tags
tagged_words = pos_tag(filtered_words)

# Keep only nouns, verbs, adjectives, and adverbs
keyword_tags = ['NN', 'NNS', 'NNP', 'NNPS', 'VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ', 'JJ', 'JJR', 'JJS', 'RB', 'RBR', 'RBS']
keywords = [word for word, tag in tagged_words if tag in keyword_tags]

# Calculate word frequencies
freq = FreqDist(keywords)

# Get the top keywords
top_keywords = [{'word': word, 'score': score} for word, score in freq.most_common(10)]

# Prepare results
results = {
    'keywords': top_keywords
}

# Print results as JSON
print(json.dumps(results))

# Return results
results
''';
      
      case 'language':
        return '''
import json
import langid

# Process the text
text = """${text.replaceAll('"""', '\"\"\"')}"""

# Detect language
lang, confidence = langid.classify(text)

# Map language codes to names
language_names = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'nl': 'Dutch',
    'ru': 'Russian',
    'ar': 'Arabic',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'fa': 'Persian',
    'sv': 'Swedish',
    'da': 'Danish',
    'fi': 'Finnish',
    'no': 'Norwegian',
    'pl': 'Polish',
    'cs': 'Czech',
    'hu': 'Hungarian',
    'el': 'Greek',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese'
}

# Get the language name
language = language_names.get(lang, lang)

# Prepare results
results = {
    'language': language,
    'language_code': lang,
    'confidence': confidence
}

# Print results as JSON
print(json.dumps(results))

# Return results
results
''';
      
      default:
        return '''
import json

results = {
    'error': 'Invalid task selected'
}

print(json.dumps(results))
results
''';
    }
  }
}
